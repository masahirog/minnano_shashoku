import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deliveryCompany", "driver"]

  connect() {
    console.log("DeliveryPlanFormController connected")
    this.filterDrivers()
  }

  filterDrivers() {
    const selectedCompanyId = this.deliveryCompanyTarget.value
    const driverOptions = this.driverTarget.querySelectorAll('option')

    console.log('Filtering drivers. Selected company ID:', selectedCompanyId)
    console.log('Total driver options:', driverOptions.length)

    driverOptions.forEach((option) => {
      if (option.value === '') {
        // 「未アサイン」オプションは常に表示
        option.style.display = ''
        option.disabled = false
      } else {
        const driverCompanyId = option.dataset.deliveryCompanyId

        console.log('Driver:', option.text, 'Company ID:', driverCompanyId)

        if (!selectedCompanyId || driverCompanyId === selectedCompanyId) {
          // 配送会社が未選択、または一致する場合は表示
          option.style.display = ''
          option.disabled = false
          console.log('  -> Showing')
        } else {
          // 一致しない場合は非表示＆無効化
          option.style.display = 'none'
          option.disabled = true
          console.log('  -> Hiding')
        }
      }
    })

    // 現在選択中のドライバーが非表示になった場合、未アサインに戻す
    const selectedOption = this.driverTarget.options[this.driverTarget.selectedIndex]
    if (selectedOption && selectedOption.disabled) {
      this.driverTarget.value = ''
    }
  }
}
