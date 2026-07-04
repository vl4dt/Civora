defmodule Civora.PilotDataset do
  @moduledoc """
  Repeatable loader for the simulated MVP pilot dataset.
  """

  import Ecto.Query, warn: false

  alias Civora.Accounts
  alias Civora.Accounts.Scope
  alias Civora.Audit.AuditEvent
  alias Civora.Budget

  alias Civora.Budget.{
    BudgetedPerformanceSheet,
    PerformanceSheet,
    ProjectBudget,
    WorkItem
  }

  alias Civora.Evidence
  alias Civora.Evidence.EvidenceAttachment
  alias Civora.Execution
  alias Civora.Execution.{ExecutedProgressEntry, WorkActivity}
  alias Civora.Projects
  alias Civora.Projects.{Project, ProjectAssignment, ProjectPhase}
  alias Civora.Quality
  alias Civora.Quality.{NonConformity, QualityControl}
  alias Civora.Repo

  alias Civora.Subcontracts
  alias Civora.Subcontracts.{Counterparty, Subcontract, SubcontractEstimate}

  @password "Civora pilot 2026!"
  @project_name "MVP Piloto Simulado - Residencial Las Palmas"
  @phase_name "Construccion piloto"

  @users [
    %{key: :admin, email: "piloto.admin@civora.test", role: :administrador},
    %{key: :director, email: "piloto.director@civora.test", role: :director_proyecto},
    %{key: :budget, email: "piloto.presupuesto@civora.test", role: :presupuesto},
    %{key: :quality, email: "piloto.calidad@civora.test", role: :calidad},
    %{key: :finance, email: "piloto.finanzas@civora.test", role: :finanzas},
    %{key: :viewer, email: "piloto.consulta@civora.test", role: :consulta}
  ]

  @performance_sheets [
    %{
      key: :earthworks,
      name: "Piloto MVP - Excavacion y nivelacion",
      description: "Rendimiento simulado para movimiento de tierra en frente residencial",
      unit: "m3",
      productivity: "42.0000",
      waste_percentage: "3.0000",
      resources: [
        %{
          category: :labor,
          name: "Operador de retroexcavadora",
          unit: "jornal",
          quantity: "0.0500"
        },
        %{category: :material, name: "Diesel de equipo", unit: "gal", quantity: "0.3500"}
      ]
    },
    %{
      key: :concrete,
      name: "Piloto MVP - Concreto estructural",
      description: "Rendimiento simulado para colado de elementos estructurales",
      unit: "m3",
      productivity: "18.0000",
      waste_percentage: "5.0000",
      resources: [
        %{
          category: :material,
          name: "Concreto premezclado 3000 PSI",
          unit: "m3",
          quantity: "1.0500"
        },
        %{category: :labor, name: "Cuadrilla de colado", unit: "jornal", quantity: "0.4500"}
      ]
    },
    %{
      key: :masonry,
      name: "Piloto MVP - Mamposteria reforzada",
      description: "Rendimiento simulado para muro de bloque reforzado",
      unit: "m2",
      productivity: "26.0000",
      waste_percentage: "6.0000",
      resources: [
        %{
          category: :material,
          name: "Bloque de concreto 6 pulgadas",
          unit: "unidad",
          quantity: "12.5000"
        },
        %{category: :labor, name: "Albanil y ayudante", unit: "jornal", quantity: "0.3800"}
      ]
    },
    %{
      key: :finishes,
      name: "Piloto MVP - Repello y afinado",
      description: "Rendimiento simulado para acabado base de paredes",
      unit: "m2",
      productivity: "32.0000",
      waste_percentage: "7.0000",
      resources: [
        %{category: :material, name: "Mortero premezclado", unit: "bolsa", quantity: "0.1800"},
        %{category: :labor, name: "Cuadrilla de acabados", unit: "jornal", quantity: "0.3000"}
      ]
    }
  ]

  @work_items [
    %{
      key: :earthworks,
      description: "Excavacion y nivelacion de plataforma",
      unit: "m3",
      quantity: "120.0000"
    },
    %{
      key: :concrete,
      description: "Concreto en zapatas y pedestales",
      unit: "m3",
      quantity: "45.0000"
    },
    %{
      key: :masonry,
      description: "Mamposteria reforzada en primer nivel",
      unit: "m2",
      quantity: "260.0000"
    },
    %{
      key: :finishes,
      description: "Repello interior y exterior",
      unit: "m2",
      quantity: "310.0000"
    }
  ]

  @counterparties [
    %{
      key: :civil,
      name: "Constructora Palmeras S. de R.L.",
      role: :subcontratista,
      contact: "Ana Rivera, ana.rivera@example.test"
    },
    %{
      key: :finishes,
      name: "Acabados Norte S.A.",
      role: :subcontratista,
      contact: "Luis Mejia, luis.mejia@example.test"
    }
  ]

  @subcontracts [
    %{
      key: :civil,
      name: "Piloto MVP - Obra gris inicial",
      counterparty: :civil,
      work_items: [:earthworks, :concrete],
      supply_modality: :mixta,
      current_contract_amount: "780000.0000",
      advance_percentage: "15.0000",
      retention_percentage: "5.0000",
      amortization_percentage: "15.0000"
    },
    %{
      key: :finishes,
      name: "Piloto MVP - Mamposteria y acabados",
      counterparty: :finishes,
      work_items: [:masonry, :finishes],
      supply_modality: :solo_mano_obra,
      current_contract_amount: "640000.0000",
      advance_percentage: "10.0000",
      retention_percentage: "5.0000",
      amortization_percentage: "10.0000"
    }
  ]

  @progress_plan %{
    earthworks: [
      %{
        quantity: "32.0000",
        location_sector: "Frente A / estacion 0+000 a 0+030",
        accepted: "32.0000"
      },
      %{
        quantity: "28.0000",
        location_sector: "Frente B / estacion 0+030 a 0+060",
        accepted: "28.0000"
      }
    ],
    concrete: [
      %{quantity: "10.0000", location_sector: "Ejes 1-3 / zapatas Z1-Z6", accepted: "10.0000"},
      %{quantity: "8.0000", location_sector: "Ejes 4-6 / pedestales P1-P4", accepted: "6.5000"}
    ],
    masonry: [
      %{quantity: "65.0000", location_sector: "Nivel 1 / ejes A-C", accepted: "65.0000"},
      %{quantity: "58.0000", location_sector: "Nivel 1 / ejes D-F", accepted: "58.0000"}
    ],
    finishes: [
      %{quantity: "72.0000", location_sector: "Modulo 1 / interiores", accepted: "72.0000"},
      %{quantity: "64.0000", location_sector: "Modulo 2 / exteriores", accepted: "64.0000"}
    ]
  }

  @doc """
  Seeds the simulated MVP pilot dataset and returns a summary map.
  """
  def seed do
    with {:ok, data} <- build_dataset() do
      {:ok, summary(data)}
    end
  end

  def seed! do
    case seed() do
      {:ok, summary} -> summary
      {:error, reason} -> raise "could not seed pilot dataset: #{inspect(reason)}"
    end
  end

  defp build_dataset do
    with {:ok, users} <- ensure_users(),
         admin_scope = Scope.for_user(users.admin),
         {:ok, project} <- ensure_project(admin_scope),
         {:ok, _assignments} <- ensure_assignments(admin_scope, project, users),
         {:ok, phase} <- ensure_phase(admin_scope, project),
         {:ok, sheets} <- ensure_performance_sheets(admin_scope),
         {:ok, work_items} <- ensure_work_items(admin_scope, project, phase),
         {:ok, _snapshots} <- ensure_budgeted_sheets(admin_scope, project, work_items, sheets),
         {:ok, budget} <- ensure_approved_budget(admin_scope, project),
         {:ok, counterparties} <- ensure_counterparties(admin_scope),
         {:ok, subcontracts} <-
           ensure_subcontracts(admin_scope, project, work_items, counterparties),
         {:ok, activities} <- ensure_activities(admin_scope, project, work_items),
         {:ok, progress} <- ensure_progress(admin_scope, project, activities),
         {:ok, controls} <- ensure_quality_controls(admin_scope, project, progress),
         {:ok, non_conformity} <-
           ensure_non_conformity(admin_scope, project, work_items, controls),
         {:ok, estimates} <- ensure_estimates(admin_scope, project, subcontracts, controls),
         {:ok, evidence} <-
           ensure_evidence(admin_scope, project, work_items, progress, controls, non_conformity) do
      {:ok,
       %{
         users: users,
         project: project,
         phase: phase,
         work_items: work_items,
         budget: budget,
         subcontracts: subcontracts,
         progress: progress,
         quality_controls: controls,
         non_conformity: non_conformity,
         estimates: estimates,
         evidence: evidence
       }}
    end
  end

  defp ensure_users do
    @users
    |> Enum.reduce_while({:ok, %{}}, fn attrs, {:ok, users} ->
      case ensure_user(attrs.email) do
        {:ok, user} -> {:cont, {:ok, Map.put(users, attrs.key, user)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ensure_user(email) do
    case Accounts.get_user_by_email(email) do
      nil -> Accounts.create_internal_user(%{email: email, password: @password})
      user -> {:ok, user}
    end
  end

  defp ensure_project(scope) do
    case Repo.get_by(Project, name: @project_name) do
      %Project{} = project ->
        {:ok, project}

      nil ->
        Projects.create_project(scope, %{
          name: @project_name,
          client_reference: "RS-36 / Dataset piloto MVP",
          status: :activo,
          description:
            "Proyecto residencial simulado para validar el flujo MVP de Civora sin informacion sensible ni obligaciones reales."
        })
    end
  end

  defp ensure_assignments(scope, project, users) do
    @users
    |> Enum.reduce_while({:ok, []}, fn %{key: key, role: role}, {:ok, assignments} ->
      user = Map.fetch!(users, key)

      case Repo.get_by(ProjectAssignment, project_id: project.id, user_id: user.id) do
        %ProjectAssignment{role: ^role} = assignment ->
          {:cont, {:ok, [assignment | assignments]}}

        %ProjectAssignment{} = assignment ->
          case Projects.update_assignment_role(scope, assignment, role) do
            {:ok, updated} -> {:cont, {:ok, [updated | assignments]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end

        nil ->
          case Projects.assign_user(scope, project, user, role) do
            {:ok, assignment} -> {:cont, {:ok, [assignment | assignments]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp ensure_phase(scope, project) do
    case Repo.get_by(ProjectPhase, project_id: project.id, name: @phase_name) do
      %ProjectPhase{} = phase ->
        {:ok, phase}

      nil ->
        Projects.create_project_phase(scope, project, %{
          name: @phase_name,
          phase_type: :construccion,
          description: "Fase unica de construccion para el dataset piloto simulado."
        })
    end
  end

  defp ensure_performance_sheets(scope) do
    reduce_keyed(@performance_sheets, fn attrs ->
      case Repo.get_by(PerformanceSheet, name: attrs.name) do
        %PerformanceSheet{} = sheet ->
          {:ok, Repo.preload(sheet, :resources)}

        nil ->
          Budget.create_performance_sheet(scope, Map.delete(attrs, :key))
      end
    end)
  end

  defp ensure_work_items(scope, project, phase) do
    reduce_keyed(@work_items, fn attrs ->
      case Repo.get_by(WorkItem, project_id: project.id, description: attrs.description) do
        %WorkItem{} = item ->
          {:ok, Repo.preload(item, :project_phase)}

        nil ->
          Budget.create_work_item(
            scope,
            project,
            attrs
            |> Map.delete(:key)
            |> Map.put(:project_phase_id, phase.id)
          )
      end
    end)
  end

  defp ensure_budgeted_sheets(scope, project, work_items, sheets) do
    work_items
    |> Enum.reduce_while({:ok, %{}}, fn {key, item}, {:ok, snapshots} ->
      case Repo.get_by(BudgetedPerformanceSheet, project_id: project.id, work_item_id: item.id) do
        %BudgetedPerformanceSheet{} = snapshot ->
          {:cont, {:ok, Map.put(snapshots, key, snapshot)}}

        nil ->
          case Budget.create_budgeted_performance_sheet(scope, project, item, sheets[key].id) do
            {:ok, snapshot} -> {:cont, {:ok, Map.put(snapshots, key, snapshot)}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp ensure_approved_budget(scope, project) do
    case Repo.get_by(ProjectBudget, project_id: project.id) do
      %ProjectBudget{status: :approved} = budget ->
        {:ok, Repo.preload(budget, [:approved_by, lines: :resources])}

      %ProjectBudget{status: :draft} = budget ->
        Budget.approve_project_budget(scope, project, budget)

      nil ->
        with {:ok, budget} <- Budget.create_project_budget(scope, project) do
          Budget.approve_project_budget(scope, project, budget)
        end
    end
  end

  defp ensure_counterparties(scope) do
    reduce_keyed(@counterparties, fn attrs ->
      case Repo.get_by(Counterparty, name: attrs.name) do
        %Counterparty{} = counterparty -> {:ok, counterparty}
        nil -> Subcontracts.create_counterparty(scope, Map.delete(attrs, :key))
      end
    end)
  end

  defp ensure_subcontracts(scope, project, work_items, counterparties) do
    reduce_keyed(@subcontracts, fn attrs ->
      case Repo.get_by(Subcontract, project_id: project.id, name: attrs.name) do
        %Subcontract{} = subcontract ->
          {:ok, Repo.preload(subcontract, [:counterparty, :work_items])}

        nil ->
          Subcontracts.create_subcontract(scope, project, %{
            name: attrs.name,
            counterparty_id: counterparties[attrs.counterparty].id,
            work_item_ids: Enum.map(attrs.work_items, &work_items[&1].id),
            supply_modality: attrs.supply_modality,
            current_contract_amount: attrs.current_contract_amount,
            advance_percentage: attrs.advance_percentage,
            retention_percentage: attrs.retention_percentage,
            amortization_percentage: attrs.amortization_percentage
          })
      end
    end)
  end

  defp ensure_activities(scope, project, work_items) do
    work_items
    |> Enum.reduce_while({:ok, %{}}, fn {key, item}, {:ok, activities} ->
      attrs = %{
        location_sector: "Frente piloto - #{item.description}",
        description: "Actividad base para #{String.downcase(item.description)}"
      }

      activity =
        Repo.one(
          from(a in WorkActivity,
            where:
              a.project_id == ^project.id and a.work_item_id == ^item.id and
                a.location_sector == ^attrs.location_sector and
                a.description == ^attrs.description
          )
        )

      case activity || Execution.create_work_activity(scope, project, item, attrs) do
        %WorkActivity{} = activity -> {:cont, {:ok, Map.put(activities, key, activity)}}
        {:ok, activity} -> {:cont, {:ok, Map.put(activities, key, activity)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ensure_progress(scope, project, activities) do
    @progress_plan
    |> Enum.reduce_while({:ok, %{}}, fn {key, entries}, {:ok, all_progress} ->
      activity = Map.fetch!(activities, key)

      case ensure_activity_progress(scope, project, activity, entries) do
        {:ok, progress} -> {:cont, {:ok, Map.put(all_progress, key, progress)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ensure_activity_progress(scope, project, activity, entries) do
    entries
    |> Enum.reduce_while({:ok, []}, fn attrs, {:ok, progress} ->
      entry =
        Repo.one(
          from(e in ExecutedProgressEntry,
            where:
              e.project_id == ^project.id and e.work_activity_id == ^activity.id and
                e.location_sector == ^attrs.location_sector and
                e.quantity == ^Decimal.new(attrs.quantity)
          )
        )

      case entry ||
             Execution.create_executed_progress(scope, project, activity, %{
               quantity: attrs.quantity,
               location_sector: attrs.location_sector
             }) do
        %ExecutedProgressEntry{} = entry -> {:cont, {:ok, progress ++ [entry]}}
        {:ok, entry} -> {:cont, {:ok, progress ++ [entry]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ensure_quality_controls(scope, project, progress) do
    progress
    |> Enum.reduce_while({:ok, %{}}, fn {key, entries}, {:ok, controls} ->
      planned_entries = Map.fetch!(@progress_plan, key)

      case ensure_entry_controls(scope, project, entries, planned_entries) do
        {:ok, item_controls} -> {:cont, {:ok, Map.put(controls, key, item_controls)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp ensure_entry_controls(scope, project, entries, planned_entries) do
    entries
    |> Enum.zip(planned_entries)
    |> Enum.reduce_while({:ok, []}, fn {entry, planned}, {:ok, controls} ->
      case Repo.get_by(QualityControl, executed_progress_entry_id: entry.id) do
        %QualityControl{} = control ->
          {:cont, {:ok, controls ++ [control]}}

        nil ->
          rejected? = Decimal.lt?(Decimal.new(planned.accepted), entry.quantity)

          attrs =
            %{
              accepted_quantity: planned.accepted,
              non_conformity_originated: rejected?
            }
            |> maybe_put_rejection_reason(rejected?)

          case Quality.create_quality_control(scope, project, entry, attrs) do
            {:ok, control} -> {:cont, {:ok, controls ++ [control]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp maybe_put_rejection_reason(attrs, false), do: attrs

  defp maybe_put_rejection_reason(attrs, true) do
    Map.put(
      attrs,
      :rejection_reason,
      "Cangrejera visible en borde de pedestal; requiere reparacion."
    )
  end

  defp ensure_non_conformity(scope, project, work_items, controls) do
    control = controls.concrete |> Enum.at(1)

    case Repo.get_by(NonConformity, quality_control_id: control.id) do
      %NonConformity{} = non_conformity ->
        {:ok, non_conformity}

      nil ->
        Quality.create_non_conformity(scope, project, work_items.concrete, %{
          quality_control_id: control.id,
          defect: "Cangrejera localizada en pedestal P3 posterior al desencofrado",
          location_sector: "Ejes 4-6 / pedestal P3",
          responsible_name: "Constructora Palmeras S. de R.L.",
          disposition: "Picar, limpiar, reparar con mortero estructural y solicitar reinspeccion",
          due_on: "2026-07-10"
        })
    end
  end

  defp ensure_estimates(scope, project, subcontracts, controls) do
    estimate_specs = [
      {:civil, [hd(controls.earthworks), hd(controls.concrete)]},
      {:finishes, [hd(controls.masonry), hd(controls.finishes)]}
    ]

    estimate_specs
    |> Enum.reduce_while({:ok, %{}}, fn {key, selected_controls}, {:ok, estimates} ->
      subcontract = Map.fetch!(subcontracts, key)

      case existing_estimate(project, subcontract) do
        %SubcontractEstimate{} = estimate ->
          {:cont,
           {:ok,
            Map.put(estimates, key, Repo.preload(estimate, lines: [:work_item, :quality_control]))}}

        nil ->
          case Subcontracts.create_subcontract_estimate(scope, project, subcontract, %{
                 quality_control_ids: Enum.map(selected_controls, & &1.id)
               }) do
            {:ok, estimate} -> {:cont, {:ok, Map.put(estimates, key, estimate)}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp existing_estimate(project, subcontract) do
    Repo.one(
      from(e in SubcontractEstimate,
        where: e.project_id == ^project.id and e.subcontract_id == ^subcontract.id,
        order_by: [asc: e.id],
        limit: 1
      )
    )
  end

  defp ensure_evidence(scope, project, work_items, progress, controls, non_conformity) do
    evidence_specs = [
      %{
        key: :progress,
        work_item: :earthworks,
        parent: {:executed_progress_entry_id, hd(progress.earthworks).id},
        original_filename: "piloto-avance-excavacion.txt",
        content_type: "text/plain",
        body: "Evidencia ficticia: fotografia simulada de excavacion y nivelacion."
      },
      %{
        key: :quality,
        work_item: :masonry,
        parent: {:quality_control_id, hd(controls.masonry).id},
        original_filename: "piloto-control-mamposteria.txt",
        content_type: "text/plain",
        body: "Evidencia ficticia: acta simulada de aceptacion de mamposteria."
      },
      %{
        key: :non_conformity,
        work_item: :concrete,
        parent: {:non_conformity_id, non_conformity.id},
        original_filename: "piloto-no-conformidad-pedestal.txt",
        content_type: "text/plain",
        body: "Evidencia ficticia: registro simulado de no conformidad en pedestal P3."
      }
    ]

    evidence_specs
    |> Enum.reduce_while({:ok, %{}}, fn spec, {:ok, attachments} ->
      item = Map.fetch!(work_items, spec.work_item)
      {parent_field, parent_id} = spec.parent

      case existing_attachment(project, item, parent_field, parent_id, spec.original_filename) do
        %EvidenceAttachment{} = attachment ->
          {:cont, {:ok, Map.put(attachments, spec.key, attachment)}}

        nil ->
          attrs =
            %{
              original_filename: spec.original_filename,
              content_type: spec.content_type,
              body: spec.body
            }
            |> Map.put(parent_field, parent_id)

          case Evidence.create_attachment(scope, project, item, attrs) do
            {:ok, attachment} -> {:cont, {:ok, Map.put(attachments, spec.key, attachment)}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
      end
    end)
  end

  defp existing_attachment(project, work_item, parent_field, parent_id, original_filename) do
    EvidenceAttachment
    |> where(
      [a],
      a.project_id == ^project.id and a.work_item_id == ^work_item.id and
        a.original_filename == ^original_filename
    )
    |> where([a], field(a, ^parent_field) == ^parent_id)
    |> Repo.one()
  end

  defp reduce_keyed(entries, fun) do
    entries
    |> Enum.reduce_while({:ok, %{}}, fn %{key: key} = attrs, {:ok, acc} ->
      case fun.(attrs) do
        {:ok, value} -> {:cont, {:ok, Map.put(acc, key, value)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp summary(data) do
    project_id = data.project.id

    %{
      project_id: project_id,
      project_name: data.project.name,
      users: map_size(data.users),
      phases: Repo.aggregate(from(p in ProjectPhase, where: p.project_id == ^project_id), :count),
      work_items: Repo.aggregate(from(w in WorkItem, where: w.project_id == ^project_id), :count),
      subcontracts:
        Repo.aggregate(from(s in Subcontract, where: s.project_id == ^project_id), :count),
      executed_progress_entries:
        Repo.aggregate(
          from(e in ExecutedProgressEntry, where: e.project_id == ^project_id),
          :count
        ),
      quality_controls:
        Repo.aggregate(from(c in QualityControl, where: c.project_id == ^project_id), :count),
      non_conformities:
        Repo.aggregate(from(n in NonConformity, where: n.project_id == ^project_id), :count),
      subcontract_estimates:
        Repo.aggregate(from(e in SubcontractEstimate, where: e.project_id == ^project_id), :count),
      evidence_attachments:
        Repo.aggregate(from(a in EvidenceAttachment, where: a.project_id == ^project_id), :count),
      audit_events:
        Repo.aggregate(from(a in AuditEvent, where: a.project_id == ^project_id), :count)
    }
  end
end
