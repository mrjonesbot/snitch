class CreateSnitchErrors < ActiveRecord::Migration[7.0]
  def change
    create_table :snitch_errors do |t|
      t.string :exception_class, null: false
      t.text :message
      t.text :backtrace
      t.string :fingerprint, null: false
      t.string :request_url
      t.string :request_method
      t.text :request_params
      t.integer :occurrence_count, default: 1
      t.integer :github_issue_number
      t.string :github_issue_url
      t.integer :github_comment_id
      t.string :status, default: "open", null: false
      t.datetime :first_occurred_at
      t.datetime :last_occurred_at
      t.timestamps
    end

    add_index :snitch_errors, :fingerprint, unique: true
    add_index :snitch_errors, :exception_class
    add_index :snitch_errors, :status
  end
end
