defmodule Civora.ProjectsTest do
  use Civora.DataCase

  import Civora.AccountsFixtures
  import Civora.ProjectsFixtures

  alias Civora.Accounts.Scope
  alias Civora.Projects
  alias Civora.Projects.{Project, ProjectAssignment}
  alias Civora.Repo

  describe "MVP roles" do
    test "exposes the six canonical roles" do
      assert Projects.available_roles() == [
               :administrador,
               :director_proyecto,
               :presupuesto,
               :calidad,
               :finanzas,
               :consulta
             ]

      assert Projects.role_label(:director_proyecto) == "Director de proyecto"
      assert Projects.role_label(:consulta) == "Consulta"
    end
  end

  describe "create_project/2" do
    test "creates the project and its first administrator atomically" do
      user = user_fixture()
      scope = Scope.for_user(user)

      assert {:ok, %Project{} = project} =
               Projects.create_project(scope, %{
                 name: "Hospital Central",
                 client_reference: "Secretaria de Salud",
                 status: :planificacion,
                 description: "Ampliacion del hospital"
               })

      assert %ProjectAssignment{role: :administrador, user_id: user_id} =
               Repo.get_by(ProjectAssignment, project_id: project.id)

      assert user_id == user.id
    end

    test "does not create an assignment when the project is invalid" do
      scope = user_fixture() |> Scope.for_user()

      assert {:error, changeset} = Projects.create_project(scope, %{name: ""})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert Repo.aggregate(ProjectAssignment, :count) == 0
    end
  end

  describe "project phases" do
    setup do
      administrator = user_fixture()
      scope = Scope.for_user(administrator)
      project = project_fixture(scope)

      %{administrator_scope: scope, project: project}
    end

    test "exposes project states and canonical phase types" do
      assert Projects.available_statuses() == [
               :planificacion,
               :activo,
               :pausado,
               :cerrado,
               :cancelado
             ]

      assert Projects.available_phase_types() == [
               :diseno,
               :presupuesto,
               :planificacion,
               :construccion,
               :supervision,
               :cierre
             ]
    end

    test "administrator creates a phase that belongs to the project", %{
      administrator_scope: scope,
      project: project
    } do
      assert {:ok, phase} =
               Projects.create_project_phase(scope, project, %{
                 name: "Construccion principal",
                 phase_type: :construccion,
                 description: "Ejecucion del alcance principal"
               })

      assert phase.project_id == project.id
      assert {:ok, [^phase]} = Projects.list_project_phases(scope, project)
    end

    test "project directors can create phases", %{
      administrator_scope: administrator_scope,
      project: project
    } do
      director = user_fixture()
      assignment_fixture(administrator_scope, project, director, :director_proyecto)
      director_scope = Scope.for_user(director)

      assert {:ok, _phase} =
               Projects.create_project_phase(director_scope, project, %{
                 name: "Supervision tecnica",
                 phase_type: :supervision,
                 description: "Inspeccion del proyecto"
               })
    end

    test "other roles cannot create phases", %{
      administrator_scope: administrator_scope,
      project: project
    } do
      viewer = user_fixture()
      assignment_fixture(administrator_scope, project, viewer, :consulta)

      assert {:error, :unauthorized} =
               Projects.create_project_phase(Scope.for_user(viewer), project, %{
                 name: "Fase no autorizada",
                 phase_type: :diseno,
                 description: "No debe persistirse"
               })
    end

    test "phase names are unique inside a project", %{
      administrator_scope: scope,
      project: project
    } do
      attrs = %{
        name: "Construccion",
        phase_type: :construccion,
        description: "Primera fase"
      }

      assert {:ok, _phase} = Projects.create_project_phase(scope, project, attrs)
      assert {:error, changeset} = Projects.create_project_phase(scope, project, attrs)
      assert "has already been taken" in errors_on(changeset).project_id
    end
  end

  describe "project access" do
    test "lists and fetches only projects assigned to the current user" do
      owner = user_fixture()
      other_user = user_fixture()
      owner_scope = Scope.for_user(owner)
      other_scope = Scope.for_user(other_user)
      project = project_fixture(owner_scope, %{name: "Assigned project"})
      _other_project = project_fixture(other_scope, %{name: "Private project"})

      assert Projects.list_projects(owner_scope) == [project]
      assert {:ok, ^project} = Projects.get_project(owner_scope, project.id)
      assert {:error, :not_found} = Projects.get_project(other_scope, project.id)
    end

    test "denies access to users without an assignment" do
      owner_scope = user_fixture() |> Scope.for_user()
      outsider_scope = user_fixture() |> Scope.for_user()
      project = project_fixture(owner_scope)

      assert Projects.authorized?(owner_scope, project, :view)
      refute Projects.authorized?(outsider_scope, project, :view)
      assert {:error, :unauthorized} = Projects.list_project_assignments(outsider_scope, project)
    end
  end

  describe "project assignments" do
    setup do
      administrator = user_fixture()
      administrator_scope = Scope.for_user(administrator)
      project = project_fixture(administrator_scope)

      %{
        administrator: administrator,
        administrator_scope: administrator_scope,
        project: project
      }
    end

    test "administrator assigns a user once per project", %{
      administrator_scope: scope,
      project: project
    } do
      user = user_fixture()

      assert {:ok, %ProjectAssignment{role: :calidad} = assignment} =
               Projects.assign_user(scope, project, user, :calidad)

      assert assignment.user_id == user.id

      assert {:error, changeset} = Projects.assign_user(scope, project, user, :finanzas)
      assert "has already been taken" in errors_on(changeset).project_id
    end

    test "rejects roles outside the MVP role set", %{
      administrator_scope: scope,
      project: project
    } do
      assert {:error, changeset} =
               Projects.assign_user(scope, project, user_fixture(), :superuser)

      assert %{role: [_]} = errors_on(changeset)
    end

    test "non-administrators cannot manage assignments", %{
      administrator_scope: administrator_scope,
      project: project
    } do
      director = user_fixture()
      assignment_fixture(administrator_scope, project, director, :director_proyecto)
      director_scope = Scope.for_user(director)

      assert {:error, :unauthorized} =
               Projects.assign_user(director_scope, project, user_fixture(), :consulta)

      refute Projects.authorized?(director_scope, project, :manage_assignments)
      assert Projects.authorized?(director_scope, project, :manage_activities)
    end

    test "authorization uses the assignment stored in the database", %{
      administrator_scope: administrator_scope,
      project: project
    } do
      other_administrator = user_fixture()
      other_scope = Scope.for_user(other_administrator)
      other_project = project_fixture(other_scope)

      protected_assignment =
        assignment_fixture(other_scope, other_project, user_fixture(), :consulta)

      forged_assignment = %{protected_assignment | project_id: project.id}

      assert {:error, :unauthorized} =
               Projects.update_assignment_role(
                 administrator_scope,
                 forged_assignment,
                 :calidad
               )

      assert {:error, :unauthorized} =
               Projects.remove_assignment(administrator_scope, forged_assignment)

      assert Repo.get!(ProjectAssignment, protected_assignment.id).role == :consulta
    end

    test "members can inspect the team assigned to their project", %{
      administrator_scope: administrator_scope,
      project: project
    } do
      viewer = user_fixture()
      assignment_fixture(administrator_scope, project, viewer)

      assert {:ok, assignments} =
               Projects.list_project_assignments(Scope.for_user(viewer), project)

      assert Enum.map(assignments, & &1.user.email) ==
               Enum.sort([administrator_scope.user.email, viewer.email])
    end

    test "administrator updates an assignment role", %{
      administrator_scope: scope,
      project: project
    } do
      assignment = assignment_fixture(scope, project, user_fixture(), :consulta)

      assert {:ok, %ProjectAssignment{role: :presupuesto}} =
               Projects.update_assignment_role(scope, assignment, :presupuesto)
    end

    test "the last administrator cannot be demoted or removed", %{
      administrator_scope: scope,
      project: project
    } do
      administrator_assignment =
        Repo.get_by!(ProjectAssignment,
          project_id: project.id,
          user_id: scope.user.id
        )

      assert {:error, :last_administrator} =
               Projects.update_assignment_role(scope, administrator_assignment, :consulta)

      assert {:error, :last_administrator} =
               Projects.remove_assignment(scope, administrator_assignment)
    end

    test "an administrator can be removed when another remains", %{
      administrator_scope: scope,
      project: project
    } do
      second_administrator =
        assignment_fixture(scope, project, user_fixture(), :administrador)

      assert {:ok, %ProjectAssignment{}} =
               Projects.remove_assignment(scope, second_administrator)

      refute Repo.get(ProjectAssignment, second_administrator.id)
    end
  end
end
