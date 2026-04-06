// SelectCar.test.ts
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SelectCar from './SelectCar.vue'

// Helper to get a fresh mount each test
function mountComponent() {
  return mount(SelectCar, {
    global: {
      stubs: {
        // Stub teleport if modal uses it
        Teleport: true,
      },
    },
  })
}

describe('SelectCar — initial render', () => {
  it('renders the panel with default cars', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.panel').exists()).toBe(true)
    expect(wrapper.findAll('.car-row').length).toBe(3)
  })

  it('shows correct saved car count in subtitle', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.topbar-sub').text()).toContain('3 saved')
  })

  it('highlights the first car (Toyota Corolla) as active by default', () => {
    const wrapper = mountComponent()
    const activeRow = wrapper.find('.car-row--active')
    expect(activeRow.exists()).toBe(true)
    expect(activeRow.find('.car-name').text()).toBe('Toyota Corolla')
  })

  it('shows active car in the hero section', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.hero-name').text()).toBe('Toyota Corolla')
    expect(wrapper.find('.hero-year').text()).toContain('2021')
  })

  it('shows the Active badge in the hero', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.hero-pulse').text()).toContain('Active')
  })
})

describe('SelectCar — switching active car', () => {
  it('updates active car when clicking a different row', async () => {
    const wrapper = mountComponent()
    const rows = wrapper.findAll('.car-row')

    // Click BMW X3 (second row)
    await rows[1].trigger('click')

    expect(wrapper.find('.hero-name').text()).toBe('BMW X3')
    expect(rows[1].classes()).toContain('car-row--active')
    expect(rows[0].classes()).not.toContain('car-row--active')
  })

  it('updates the subtitle when active car changes', async () => {
    const wrapper = mountComponent()
    const rows = wrapper.findAll('.car-row')
    await rows[2].trigger('click')

    expect(wrapper.find('.topbar-sub').text()).toContain('Tesla Model 3')
  })

  it('marks the checkmark button as selected for active car', async () => {
    const wrapper = mountComponent()
    const rows = wrapper.findAll('.car-row')
    await rows[1].trigger('click')

    const checkBtns = wrapper.findAll('.action-btn--active')
    expect(checkBtns[1].classes()).toContain('selected')
    expect(checkBtns[0].classes()).not.toContain('selected')
  })
})

describe('SelectCar — adding a car', () => {
  it('opens the modal when Add button is clicked', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')
    expect(wrapper.find('.modal').exists()).toBe(true)
  })

  it('modal title says add when opening fresh', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')
    expect(wrapper.find('.modal-title').text()).toContain('Pridėti')
  })

  it('Save button is disabled when form is empty', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')
    const saveBtn = wrapper.find('.btn-save')
    expect(saveBtn.attributes('disabled')).toBeDefined()
  })

  it('adds a new car to the list after filling form and saving', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')

    // Select make
    const selects = wrapper.findAll('.fselect')
    await selects[0].setValue('Audi')
    await selects[0].trigger('change')

    // Select model (re-query after reactivity)
    await wrapper.vm.$nextTick()
    const selects2 = wrapper.findAll('.fselect')
    await selects2[1].setValue('A3')

    // Select year
    await wrapper.vm.$nextTick()
    const selects3 = wrapper.findAll('.fselect')
    await selects3[2].setValue(2022)

    await wrapper.find('.btn-save').trigger('click')

    expect(wrapper.findAll('.car-row').length).toBe(4)
    expect(wrapper.text()).toContain('Audi A3')
  })

  it('closes the modal after saving', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')

    const selects = wrapper.findAll('.fselect')
    await selects[0].setValue('Ford')
    await selects[0].trigger('change')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[1].setValue('Focus')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[2].setValue(2021)

    await wrapper.find('.btn-save').trigger('click')
    expect(wrapper.find('.modal').exists()).toBe(false)
  })

  it('closes modal on Cancel without adding', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')
    await wrapper.find('.btn-cancel').trigger('click')

    expect(wrapper.find('.modal').exists()).toBe(false)
    expect(wrapper.findAll('.car-row').length).toBe(3)
  })

  it('closes modal when clicking the × button', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')
    await wrapper.find('.modal-close').trigger('click')
    expect(wrapper.find('.modal').exists()).toBe(false)
  })

  it('updates car count in subtitle after adding', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')

    const selects = wrapper.findAll('.fselect')
    await selects[0].setValue('Skoda')
    await selects[0].trigger('change')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[1].setValue('Octavia')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[2].setValue(2020)

    await wrapper.find('.btn-save').trigger('click')
    expect(wrapper.find('.topbar-sub').text()).toContain('4 saved')
  })
})

describe('SelectCar — editing a car', () => {
  it('opens modal with pre-filled data when edit is clicked', async () => {
    const wrapper = mountComponent()
    const editBtns = wrapper.findAll('.action-btn:not(.action-btn--active):not(.action-btn--del)')
    await editBtns[0].trigger('click')

    expect(wrapper.find('.modal').exists()).toBe(true)
    expect(wrapper.find('.modal-title').text()).toContain('Redaguoti')
    const makeSelect = wrapper.findAll('.fselect')[0]
    expect((makeSelect.element as HTMLSelectElement).value).toBe('Toyota')
  })

  it('saves edited car data correctly', async () => {
    const wrapper = mountComponent()
    const editBtns = wrapper.findAll('.action-btn:not(.action-btn--active):not(.action-btn--del)')
    await editBtns[1].trigger('click') // Edit BMW X3

    const selects = wrapper.findAll('.fselect')
    await selects[0].setValue('Audi')
    await selects[0].trigger('change')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[1].setValue('A4')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[2].setValue(2023)

    await wrapper.find('.btn-save').trigger('click')

    expect(wrapper.text()).toContain('Audi A4')
    expect(wrapper.text()).not.toContain('BMW X3')
    expect(wrapper.findAll('.car-row').length).toBe(3) // count unchanged
  })
})

describe('SelectCar — deleting a car', () => {
  it('removes a car from the list', async () => {
    const wrapper = mountComponent()
    const delBtns = wrapper.findAll('.action-btn--del')
    await delBtns[2].trigger('click') // Delete Tesla

    expect(wrapper.findAll('.car-row').length).toBe(2)
    expect(wrapper.text()).not.toContain('Tesla Model 3')
  })

  it('updates car count after deletion', async () => {
    const wrapper = mountComponent()
    await wrapper.findAll('.action-btn--del')[0].trigger('click')
    expect(wrapper.find('.topbar-sub').text()).toContain('2 saved')
  })

  it('reassigns active car when active one is deleted', async () => {
    const wrapper = mountComponent()
    // Toyota (id=1) is active by default — delete it
    await wrapper.findAll('.action-btn--del')[0].trigger('click')

    // Active car should now be BMW X3 (first remaining)
    expect(wrapper.find('.hero-name').text()).toBe('BMW X3')
  })

  it('shows empty state when all cars are deleted', async () => {
    const wrapper = mountComponent()
    // Delete all 3
    for (let i = 0; i < 3; i++) {
      await wrapper.findAll('.action-btn--del')[0].trigger('click')
    }
    expect(wrapper.find('.list-empty').exists()).toBe(true)
  })

  it('shows add button in empty state', async () => {
    const wrapper = mountComponent()
    for (let i = 0; i < 3; i++) {
      await wrapper.findAll('.action-btn--del')[0].trigger('click')
    }
    expect(wrapper.find('.btn-add-inline').exists()).toBe(true)
  })
})

describe('SelectCar — model cascade', () => {
  it('resets model when make changes', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')

    const selects = wrapper.findAll('.fselect')
    await selects[0].setValue('Toyota')
    await selects[0].trigger('change')
    await wrapper.vm.$nextTick()
    await wrapper.findAll('.fselect')[1].setValue('Camry')

    // Change make — model should reset
    await wrapper.findAll('.fselect')[0].setValue('BMW')
    await wrapper.findAll('.fselect')[0].trigger('change')
    await wrapper.vm.$nextTick()

    const modelSelect = wrapper.findAll('.fselect')[1]
    expect((modelSelect.element as HTMLSelectElement).value).toBe('')
  })

  it('model select is disabled until make is chosen', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')

    const modelField = wrapper.findAll('.field')[1]
    expect(modelField.classes()).toContain('field--off')
  })

  it('year select is disabled until model is chosen', async () => {
    const wrapper = mountComponent()
    await wrapper.find('.btn-add').trigger('click')

    const yearField = wrapper.findAll('.field')[2]
    expect(yearField.classes()).toContain('field--off')
  })
})