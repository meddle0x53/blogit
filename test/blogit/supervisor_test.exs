defmodule Blogit.SupervisorTest do
  use ExUnit.Case

  alias Blogit.Components.Supervisor, as: Components

  setup_all do
    {:ok, pid} = Blogit.Supervisor.start_link(Blogit.RepositoryProviders.Memory)
    %{pid: pid}
  end

  test "Blogit.Supervisor.start_link starts a process", %{pid: pid} do
    assert is_pid(pid)
    assert Process.alive?(pid)
  end

  test "starts a Blogit.Components.Supervisor process", %{pid: pid} do
    spec = Supervisor.which_children(pid) |> Enum.find(fn {name, _, type, _} ->
      name == Components && type == :supervisor
    end)
    refute is_nil(spec)

    {Components, child_pid, :supervisor, [Components]} = spec

    assert Process.alive?(child_pid)
  end

  test "starts a Task.Supervisor process, named :tasks_supervisor",
  %{pid: pid} do
    spec = Supervisor.which_children(pid) |> Enum.find(fn {name, _, type, _} ->
      name == Task.Supervisor && type == :supervisor
    end)
    refute is_nil(spec)

    {Task.Supervisor, child_pid, :supervisor, [Task.Supervisor]} = spec

    assert Process.alive?(child_pid)
    assert child_pid == Process.whereis(:tasks_supervisor)
  end

  test "starts a Blogit.Server process", %{pid: pid} do
    spec = Supervisor.which_children(pid) |> Enum.find(fn {name, _, type, _} ->
      name == Blogit.Server && type == :worker
    end)
    refute is_nil(spec)

    {Blogit.Server, child_pid, :worker, [Blogit.Server]} = spec

    assert Process.alive?(child_pid)
  end
end
