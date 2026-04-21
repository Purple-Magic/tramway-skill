# Tramway Chat Lazy Loading Recipe

Load this file when the task is about loading older messages in `tramway_chat` as the user scrolls upward.

## Goal

- Let the user load earlier chat history without reloading the page or losing the current reading position.

## Preferred Approach

- Render the latest page of messages in the initial `tramway_chat` call.
- Load older pages through a dedicated `Chats::MessagesController#index` endpoint with `chat_id` and `page`.
- Keep the controller as a command endpoint:
  - return `204 No Content` when there are no more pages
  - broadcast older messages through `tramway_chat_prepend_messages(chat_id:, messages:)`
  - return `200 OK` with an empty body when messages were broadcast
- Let Stimulus know only the request status.
- Do not make the lazy-loading action return Turbo Stream HTML to the custom JS fetch flow.
- Preserve the visible message anchor after prepend so the user does not see a jump or flicker.

## Where Logic Should Live

- Put message pagination and message-shape mapping in a decorator or other presenter-style layer.
- Keep the controller thin.
- Put scroll detection, request lifecycle, and anchor preservation in a Stimulus controller attached to the chat wrapper.

## Data Rules

- Use `chat.uuid` for the client request and broadcast target.
- The messages payload passed to `tramway_chat_prepend_messages` should be an array of hashes with at least:
  - `id`
  - `type`
  - `text`
  - `sent_at`
- Order the queried records from newest to oldest for pagination, then reverse the page collection before broadcasting so the prepended block still reads top-to-bottom.
- Return `204` only when the selected page is empty.

## UI Guidance

- Render `tramway_chat` with the newest page only.
- Attach a Stimulus controller to the wrapper around the chat.
- Trigger loading when the messages container reaches the top.
- Preserve the currently visible message after prepend by capturing the first visible DOM node before the request and restoring its offset when the prepend mutation lands.
- Avoid scroll-height-only restoration if it causes visible flicker; prefer anchor-based restoration through a one-shot `MutationObserver`.

## Suggested Flow

Example flow for lazy loading a `Chat` transcript:
1. The chat show page renders only the latest page in `tramway_chat`. The call should look like this:

```haml
= tramway_chat chat_id: @chat.uuid,
  messages: @chat.transcript_messages(page: 1),
  message_form: @message_form,
  send_message_path: chats_messages_path
```

2. The decorator should paginate and normalize message data. It should look like this:

```ruby
class ChatDecorator < Tramway::BaseDecorator
  MESSAGES_PER_PAGE = 20

  def transcript_messages(page: 1)
    paginated_messages(page).map do |message|
      {
        id: message.uuid,
        type: message.sender_id == object.creator_id ? :sent : :received,
        text: message.text,
        sent_at: message.created_at
      }
    end
  end

  private

  def paginated_messages(page)
    Chats::Message.where(chat: object)
                  .order(created_at: :desc, id: :desc)
                  .page(page)
                  .per(MESSAGES_PER_PAGE)
                  .reverse
  end
end
```

3. The controller broadcasts older messages and returns only status. It should look like this:

```ruby
class Chats::MessagesController < ApplicationController
  def index
    chat = Chat.find_by!(uuid: params[:chat_id])
    messages = tramway_decorate(chat).transcript_messages(page: params[:page])

    return head :no_content if messages.blank?

    tramway_chat_prepend_messages(chat_id: chat.uuid, messages:)
    head :ok
  end
end
```

4. The Stimulus controller should detect top scroll, send the request, and preserve the visible anchor on prepend. The implementation should be like this:

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    chatId: String,
    messagesPath: String,
    nextPage: Number
  }

  initialize() {
    this.hasMoreMessages = true
    this.isLoading = false
  }

  connect() {
    this.messagesElement = this.element.querySelector("#messages")
    this.boundHandleScroll = this.handleScroll.bind(this)

    if (this.messagesElement) {
      this.messagesElement.addEventListener("scroll", this.boundHandleScroll)
      this.scheduleInitialLoad()
    }
  }

  disconnect() {
    if (this.messagesElement) {
      this.messagesElement.removeEventListener("scroll", this.boundHandleScroll)
    }
  }

  handleScroll() {
    if (!this.messagesElement || this.messagesElement.scrollTop > 0) return

    this.loadMessages()
  }

  async scheduleInitialLoad() {
    await this.nextFrame()
    await this.nextFrame()

    this.loadMessages()
  }

  async loadMessages() {
    if (!this.hasMoreMessages || this.isLoading) return

    this.isLoading = true
    this.messagesElement.dataset.preserveScroll = "true"
    const anchorData = this.captureAnchor()
    const pendingUpdate = this.waitForMessagesUpdate(anchorData)

    try {
      const response = await fetch(
        `${this.messagesPathValue}?chat_id=${encodeURIComponent(this.chatIdValue)}&page=${this.nextPageValue}`,
        {
          headers: { Accept: "text/vnd.turbo-stream.html" }
        }
      )

      if (response.status === 204) {
        pendingUpdate.cancel()
        this.hasMoreMessages = false
        return
      }

      if (!response.ok) {
        pendingUpdate.cancel()
        throw new Error(`Failed to load messages: ${response.status}`)
      }

      await pendingUpdate.promise
      this.nextPageValue += 1
    } finally {
      delete this.messagesElement.dataset.preserveScroll
      this.isLoading = false
    }
  }

  captureAnchor() {
    const containerTop = this.messagesElement.getBoundingClientRect().top
    const children = Array.from(this.messagesElement.children)

    const element = children.find((child) => {
      return child.getBoundingClientRect().bottom > containerTop
    })

    if (!element) return null

    return {
      element,
      topOffset: element.getBoundingClientRect().top - containerTop
    }
  }

  waitForMessagesUpdate(anchorData) {
    let resolved = false
    let observer = null
    let timeoutId = null
    let resolvePromise = null

    const promise = new Promise((resolve) => {
      resolvePromise = resolve

      const finish = () => {
        if (resolved) return

        resolved = true
        observer?.disconnect()
        if (timeoutId) clearTimeout(timeoutId)
        resolve()
      }

      observer = new MutationObserver(() => {
        if (anchorData?.element?.isConnected) {
          const containerTop = this.messagesElement.getBoundingClientRect().top
          const newTopOffset = anchorData.element.getBoundingClientRect().top - containerTop

          this.messagesElement.scrollTop += newTopOffset - anchorData.topOffset
        }

        finish()
      })

      observer.observe(this.messagesElement, { childList: true })
      timeoutId = setTimeout(finish, 1500)
    })

    return {
      promise,
      cancel() {
        if (resolved) return
        resolved = true
        observer?.disconnect()
        if (timeoutId) clearTimeout(timeoutId)
        resolvePromise?.()
      }
    }
  }

  nextFrame() {
    return new Promise((resolve) => requestAnimationFrame(resolve))
  }
}
```
