import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "item", "template", "menuSelect", "quantity", "unitPrice", "subtotal"]

  connect() {
    console.log("✅ Nested order items controller connected")
    this.index = this.itemTargets.length
    console.log("📊 Initial items count:", this.index)
  }

  addItem(event) {
    event.preventDefault()
    console.log("➕ Add item button clicked")

    if (!this.hasTemplateTarget) {
      console.error("❌ Template target not found!")
      return
    }

    const timestamp = new Date().getTime()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)
    console.log("📝 Adding new item with timestamp:", timestamp)

    this.containerTarget.insertAdjacentHTML('beforeend', content)
    this.index++
    console.log("✅ Item added. Total items:", this.index)
  }

  removeItem(event) {
    event.preventDefault()
    const item = event.target.closest('[data-nested-order-items-target="item"]')

    if (item) {
      // 新規アイテムの場合は削除、既存アイテムの場合は_destroyをセット
      const destroyInput = item.querySelector('input[name$="[_destroy]"]')
      if (destroyInput) {
        destroyInput.value = '1'
        item.style.display = 'none'
      } else {
        item.remove()
      }
    }
  }

  toggleDestroy(event) {
    const item = event.target.closest('[data-nested-order-items-target="item"]')
    if (event.target.checked) {
      item.style.opacity = '0.5'
    } else {
      item.style.opacity = '1'
    }
  }

  updatePrice(event) {
    const item = event.target.closest('[data-nested-order-items-target="item"]')
    if (!item) return

    const select = event.target
    const selectedOption = select.options[select.selectedIndex]
    const price = selectedOption.getAttribute('data-price')

    const unitPriceInput = item.querySelector('[data-nested-order-items-target="unitPrice"]')
    if (unitPriceInput && price) {
      unitPriceInput.value = price
      this.calculateSubtotal({ target: item })
    }
  }

  calculateSubtotal(event) {
    const item = event.target.closest ?
                 event.target.closest('[data-nested-order-items-target="item"]') :
                 event.target

    if (!item) return

    const quantityInput = item.querySelector('[data-nested-order-items-target="quantity"]')
    const unitPriceInput = item.querySelector('[data-nested-order-items-target="unitPrice"]')
    const subtotalInput = item.querySelector('[data-nested-order-items-target="subtotal"]')

    if (quantityInput && unitPriceInput && subtotalInput) {
      const quantity = parseFloat(quantityInput.value) || 0
      const unitPrice = parseFloat(unitPriceInput.value) || 0
      const subtotal = quantity * unitPrice

      subtotalInput.value = subtotal.toFixed(2)
    }
  }
}
