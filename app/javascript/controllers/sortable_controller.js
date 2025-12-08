import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
export default class extends Controller {
  connect() {
    this.initializeSortable()
  }

  initializeSortable() {
    // Orderカードのソート（未アサインカラム）
    const orderGroups = this.element.querySelectorAll('[data-sortable-group="orders"]')
    orderGroups.forEach(group => {
      new Sortable(group, {
        group: 'orders',
        animation: 150,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        onEnd: this.handleOrderMove.bind(this)
      })
    })

    // DeliveryPlanItemsのソート（配送計画カラム内）
    const itemGroups = this.element.querySelectorAll('[data-sortable-group="items"]')
    itemGroups.forEach(group => {
      new Sortable(group, {
        group: {
          name: 'items',
          put: ['orders'] // Orderカードを受け入れ
        },
        animation: 150,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        onEnd: this.handleItemReorder.bind(this)
      })
    })
  }

  handleOrderMove(event) {
    const orderId = event.item.dataset.orderId
    const toPlanId = event.to.dataset.planId

    // 未アサインから配送計画へのドロップの場合
    if (toPlanId && event.from !== event.to) {
      this.addOrderToPlan(orderId, toPlanId)
    }
  }

  handleItemReorder(event) {
    const planId = event.to.dataset.planId

    if (!planId) return

    // 新しい順序を取得
    const itemIds = Array.from(event.to.children)
      .filter(child => child.dataset.itemId)
      .map(item => item.dataset.itemId)

    this.updateItemOrder(planId, itemIds)
  }

  addOrderToPlan(orderId, planId) {
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    fetch(`/admin/delivery_plans/${planId}/add_orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ order_id: orderId })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // ページをリロードして最新の状態を表示
        window.location.reload()
      } else {
        alert('エラー: ' + data.message)
        window.location.reload()
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('エラーが発生しました')
      window.location.reload()
    })
  }

  updateItemOrder(planId, itemIds) {
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    fetch(`/admin/delivery_plans/${planId}/reorder_items`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ items: itemIds })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      // 順序変更は成功してもリロード不要
      console.log('順序を更新しました')
    })
    .catch(error => {
      console.error('Error:', error)
      alert('順序の更新に失敗しました')
    })
  }
}
