import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
export default class extends Controller {
  connect() {
    // DOMが完全に読み込まれるまで少し待つ
    requestAnimationFrame(() => {
      this.initializeSortable()
      this.restoreScrollPosition()
    })
  }

  restoreScrollPosition() {
    const savedScrollPosition = localStorage.getItem('deliveryPlanScrollPosition')
    if (savedScrollPosition) {
      const scrollData = JSON.parse(savedScrollPosition)
      const planColumn = document.querySelector(`.plan-column[data-plan-id="${scrollData.planId}"]`)
      if (planColumn) {
        const columnContent = planColumn.querySelector('.column-content')
        if (columnContent) {
          columnContent.scrollTop = scrollData.scrollTop
        }
      }
      localStorage.removeItem('deliveryPlanScrollPosition')
    }
  }

  saveScrollPosition(planId) {
    const planColumn = document.querySelector(`.plan-column[data-plan-id="${planId}"]`)
    if (planColumn) {
      const columnContent = planColumn.querySelector('.column-content')
      if (columnContent) {
        localStorage.setItem('deliveryPlanScrollPosition', JSON.stringify({
          planId: planId,
          scrollTop: columnContent.scrollTop
        }))
      }
    }
  }

  initializeSortable() {
    // Orderカードのソート（未アサインカラム）
    const orderGroups = this.element.querySelectorAll('[data-sortable-group="orders"]')
    orderGroups.forEach(group => {
      new Sortable(group, {
        group: 'orders',
        animation: 150,
        delay: 100,
        delayOnTouchOnly: true,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        onEnd: this.handleOrderMove.bind(this),
        onClick: (event) => {
          // クリック時はリンクの動作を許可
          return true
        }
      })
    })

    // タイムスロット内のDeliveryPlanItemsのソート
    const timeSlots = this.element.querySelectorAll('.time-slot .slot-cards')
    timeSlots.forEach(slotCards => {
      const timeSlot = slotCards.closest('.time-slot')
      new Sortable(slotCards, {
        group: {
          name: 'items',
          put: ['orders', 'items'] // Orderカードとアイテム同士の移動を両方許可
        },
        animation: 150,
        delay: 100,
        delayOnTouchOnly: true,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        onEnd: this.handleTimeSlotDrop.bind(this),
        onClick: (event) => {
          // クリック時はリンクの動作を許可
          return true
        }
      })
    })
  }

  handleOrderMove(event) {
    const orderId = event.item.dataset.orderId
    const toSlot = event.to.closest('.time-slot')
    const toPlanId = toSlot ? toSlot.dataset.planId : event.to.dataset.planId

    // 未アサインから配送計画へのドロップの場合
    if (toPlanId && event.from !== event.to) {
      this.addOrderToPlan(orderId, toPlanId)
    }
  }

  handleTimeSlotDrop(event) {
    const timeSlot = event.to.closest('.time-slot')
    const time = timeSlot.dataset.time
    const toPlanId = timeSlot.dataset.planId
    const fromSlot = event.from.closest('.time-slot')
    const fromPlanId = fromSlot ? fromSlot.dataset.planId : null

    // Orderカードからの移動の場合（未アサインカラムから）
    const isFromUnassigned = event.from.dataset.sortableGroup === 'orders'
    if (isFromUnassigned && event.item.dataset.orderId) {
      const orderId = event.item.dataset.orderId
      this.addOrderToPlan(orderId, toPlanId)
      return
    }

    // ルート間移動の場合（時間は変更しない、同じOrderの4つのアイテムをセットで移動）
    if (fromPlanId && toPlanId && fromPlanId !== toPlanId) {
      const movedItem = event.item
      const orderId = movedItem.dataset.orderId

      if (orderId) {
        const allItemsToMove = []

        // ドラッグしたアイテム自体を最初に追加
        allItemsToMove.push(movedItem.dataset.itemId)

        // 移動元のプラン全体から同じOrder IDを持つ他のアイテムを探す
        const fromPlanColumn = document.querySelector(`.plan-column[data-plan-id="${fromPlanId}"]`)
        if (fromPlanColumn) {
          fromPlanColumn.querySelectorAll('.plan-item-card').forEach(card => {
            const cardOrderId = card.dataset.orderId
            if (cardOrderId && cardOrderId === orderId && card.dataset.itemId !== movedItem.dataset.itemId) {
              allItemsToMove.push(card.dataset.itemId)
            }
          })
        }

        // 一括移動（時間は保持）
        this.moveItemsToNewPlan(allItemsToMove, fromPlanId, toPlanId)
        return
      }
    }

    // 同一プラン内での時間変更（個別アイテムのみ）
    const movedItem = event.item
    const itemId = movedItem.dataset.itemId

    if (itemId) {
      // ドラッグしたアイテムの時間のみを更新
      this.updateItemTime(toPlanId, itemId, time)
    }
  }

  handleItemReorder(event) {
    const fromPlanId = event.from.dataset.planId
    const toPlanId = event.to.dataset.planId

    if (!toPlanId) return

    // ルート間移動の場合
    if (fromPlanId && toPlanId && fromPlanId !== toPlanId) {
      const movedItem = event.item
      const orderIds = movedItem.dataset.orderIds

      if (orderIds) {
        // 同じOrder IDを持つ他のアイテムを取得
        const orderIdArray = orderIds.split(',')
        const fromGroup = event.from
        const allItemsToMove = []

        // ドラッグしたアイテム自体を最初に追加
        allItemsToMove.push(movedItem.dataset.itemId)

        // 移動元から同じOrder IDを持つ他のアイテムを探す
        Array.from(fromGroup.children).forEach(child => {
          const childOrderIds = child.dataset.orderIds
          if (childOrderIds && child.dataset.itemId !== movedItem.dataset.itemId) {
            const childOrderIdArray = childOrderIds.split(',')
            // いずれかのOrder IDが一致する場合
            if (orderIdArray.some(id => childOrderIdArray.includes(id))) {
              allItemsToMove.push(child.dataset.itemId)
            }
          }
        })

        // 一括移動処理
        this.moveItemsToNewPlan(allItemsToMove, fromPlanId, toPlanId)
        return
      }
    }

    // 同一ルート内での並び替え
    const itemIds = Array.from(event.to.children)
      .filter(child => child.dataset.itemId)
      .map(item => item.dataset.itemId)

    this.updateItemOrder(toPlanId, itemIds)
  }

  addOrderToPlan(orderId, planId) {
    this.saveScrollPosition(planId)
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

  moveItemsToNewPlan(itemIds, fromPlanId, toPlanId) {
    this.saveScrollPosition(toPlanId)
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    fetch(`/admin/delivery_plans/${toPlanId}/move_items`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        item_ids: itemIds,
        from_plan_id: fromPlanId
      })
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
      alert('アイテムの移動に失敗しました')
      window.location.reload()
    })
  }

  updateItemTime(planId, itemId, time) {
    this.saveScrollPosition(planId)
    const csrfToken = document.querySelector('[name="csrf-token"]').content

    fetch(`/admin/delivery_plans/${planId}/update_item_time`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        item_id: itemId,
        scheduled_time: time
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        window.location.reload()
      } else {
        alert('エラー: ' + data.message)
        window.location.reload()
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('時間の更新に失敗しました')
      window.location.reload()
    })
  }
}
