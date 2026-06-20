defmodule Civora.Repo.Migrations.CreateProjectBudgets do
  use Ecto.Migration

  def up do
    create table(:project_budgets) do
      add :project_id, references(:projects, on_delete: :restrict), null: false
      add :status, :string, null: false, default: "draft"
      add :approved_at, :utc_datetime
      add :approved_by_id, references(:users, on_delete: :restrict)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_budgets, [:project_id])

    create constraint(:project_budgets, :project_budgets_status_check,
             check: "status IN ('draft', 'approved')"
           )

    create constraint(:project_budgets, :project_budgets_approval_fields_check,
             check:
               "(status = 'draft' AND approved_at IS NULL AND approved_by_id IS NULL) OR " <>
                 "(status = 'approved' AND approved_at IS NOT NULL AND approved_by_id IS NOT NULL)"
           )

    create table(:project_budget_lines) do
      add :project_budget_id, references(:project_budgets, on_delete: :delete_all), null: false
      add :source_work_item_id, references(:work_items, on_delete: :restrict), null: false

      add :source_budgeted_performance_sheet_id,
          references(:budgeted_performance_sheets, on_delete: :restrict)

      add :phase_name, :string, null: false
      add :description, :text, null: false
      add :unit, :string, null: false
      add :quantity, :decimal, precision: 18, scale: 4, null: false
      add :sheet_name, :string
      add :sheet_description, :text
      add :sheet_unit, :string
      add :productivity, :decimal, precision: 18, scale: 4
      add :waste_percentage, :decimal, precision: 7, scale: 4

      timestamps(type: :utc_datetime)
    end

    create unique_index(:project_budget_lines, [:project_budget_id, :source_work_item_id],
             name: :project_budget_lines_budget_work_item_index
           )

    create index(:project_budget_lines, [:source_work_item_id])
    create index(:project_budget_lines, [:source_budgeted_performance_sheet_id])

    create constraint(:project_budget_lines, :project_budget_lines_quantity_positive,
             check: "quantity > 0"
           )

    create table(:project_budget_line_resources) do
      add :project_budget_line_id,
          references(:project_budget_lines, on_delete: :delete_all),
          null: false

      add :category, :string, null: false
      add :name, :string, null: false
      add :unit, :string, null: false
      add :quantity, :decimal, precision: 18, scale: 4, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:project_budget_line_resources, [:project_budget_line_id])

    create constraint(
             :project_budget_line_resources,
             :project_budget_line_resources_category_check,
             check: "category IN ('material', 'labor')"
           )

    create constraint(
             :project_budget_line_resources,
             :project_budget_line_resources_quantity_positive,
             check: "quantity > 0"
           )

    execute """
    CREATE FUNCTION prevent_approved_project_budget_mutation()
    RETURNS trigger AS $$
    BEGIN
      IF OLD.status = 'approved' THEN
        RAISE EXCEPTION 'approved project budgets are immutable';
      END IF;

      RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER project_budgets_immutable_after_approval
    BEFORE UPDATE OR DELETE ON project_budgets
    FOR EACH ROW EXECUTE FUNCTION prevent_approved_project_budget_mutation();
    """

    execute """
    CREATE FUNCTION prevent_approved_project_budget_child_mutation()
    RETURNS trigger AS $$
    DECLARE
      old_budget_id bigint;
      new_budget_id bigint;
    BEGIN
      IF TG_TABLE_NAME = 'project_budget_lines' THEN
        IF TG_OP <> 'INSERT' THEN
          old_budget_id := OLD.project_budget_id;
        END IF;

        IF TG_OP <> 'DELETE' THEN
          new_budget_id := NEW.project_budget_id;
        END IF;
      ELSE
        IF TG_OP <> 'INSERT' THEN
          SELECT project_budget_id INTO old_budget_id
          FROM project_budget_lines
          WHERE id = OLD.project_budget_line_id;
        END IF;

        IF TG_OP <> 'DELETE' THEN
          SELECT project_budget_id INTO new_budget_id
          FROM project_budget_lines
          WHERE id = NEW.project_budget_line_id;
        END IF;
      END IF;

      IF EXISTS (
        SELECT 1
        FROM project_budgets
        WHERE status = 'approved' AND id IN (old_budget_id, new_budget_id)
      ) THEN
        RAISE EXCEPTION 'approved project budget contents are immutable';
      END IF;

      RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
    END;
    $$ LANGUAGE plpgsql;
    """

    execute """
    CREATE TRIGGER project_budget_lines_immutable_after_approval
    BEFORE INSERT OR UPDATE OR DELETE ON project_budget_lines
    FOR EACH ROW EXECUTE FUNCTION prevent_approved_project_budget_child_mutation();
    """

    execute """
    CREATE TRIGGER project_budget_line_resources_immutable_after_approval
    BEFORE INSERT OR UPDATE OR DELETE ON project_budget_line_resources
    FOR EACH ROW EXECUTE FUNCTION prevent_approved_project_budget_child_mutation();
    """
  end

  def down do
    execute "DROP TRIGGER project_budget_line_resources_immutable_after_approval ON project_budget_line_resources"
    execute "DROP TRIGGER project_budget_lines_immutable_after_approval ON project_budget_lines"
    execute "DROP FUNCTION prevent_approved_project_budget_child_mutation()"
    execute "DROP TRIGGER project_budgets_immutable_after_approval ON project_budgets"
    execute "DROP FUNCTION prevent_approved_project_budget_mutation()"

    drop table(:project_budget_line_resources)
    drop table(:project_budget_lines)
    drop table(:project_budgets)
  end
end
