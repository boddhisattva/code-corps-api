defmodule CodeCorps.SparkPost.Emails.ProjectUserRequestTest do
  use CodeCorps.DbAccessCase

  alias CodeCorps.SparkPost.Emails.ProjectUserRequest

  describe "build/1" do
    test "provides substitution data for all keys used by template" do
      project = insert(:project)
      project_user = insert(:project_user, project: project)

      %{substitution_data: data} = ProjectUserRequest.build(project_user)

      expected_keys =
        "project-user-request"
        |> CodeCorps.SparkPostHelpers.get_keys_used_by_template
      assert data |> Map.keys == expected_keys
    end

    test "builds correct transmission model" do
      project = insert(:project)
      %{user: requesting_user} = project_user = insert(:project_user, project: project)
      %{user: owner_1} = insert(:project_user, project: project, role: "owner")
      %{user: owner_2} = insert(:project_user, project: project, role: "owner")

      %{substitution_data: data, recipients: [recipient_1, recipient_2]} =
        ProjectUserRequest.build(project_user)

      assert data.from_name == "Code Corps"
      assert data.from_email == "team@codecorps.org"

      assert data.contributors_url == "http://localhost:4200/#{project.organization.slug}/#{project.slug}/people"
      assert data.project_title == project.title
      assert data.project_logo_url == "#{Application.get_env(:code_corps, :asset_host)}/icons/project_default_large_.png"
      assert data.user_image_url == "#{Application.get_env(:code_corps, :asset_host)}/icons/user_default_large_.png"
      assert data.user_first_name == requesting_user.first_name
      assert data.subject == "#{requesting_user.first_name} wants to join #{project.title}"

      assert recipient_1.address.email == owner_1.email
      assert recipient_1.address.name == owner_1.first_name
      assert recipient_2.address.email == owner_2.email
      assert recipient_2.address.name == owner_2.first_name
    end
  end
end