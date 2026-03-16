class CreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.text :comment, null: false
      t.integer :rating, null: false

      t.timestamps
    end
  end
end

