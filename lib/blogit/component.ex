defmodule Blogit.Component do
  @moduledoc """
  Contains common logic for creating and naming `Blogit` component processes.
  A component is a `GenServer`, but instead declaring:

  ```
  use GenServer
  ```

  it should declare:

  ```
  use Blogit.Component
  ```

  This will make it a `GenServer` and will create the `start_link/1` function
  for creating the component process for the module.

  This will also add the `name/1` function, which creates uniq name/id for the
  component based on the given `language`. This name/id is used by the
  `Blogit.Components.Supervisor` process.
  """

  @doc false
  defmacro __using__(options \\ []) do
    quote do
      default_base_name =
        __MODULE__
        |> to_string()
        |> String.split(".")
        |> List.last()
        |> Macro.underscore()

      base_name_string = Keyword.get(unquote(options), :base_name, default_base_name)

      # Code used by every component process module:

      use GenServer

      alias Blogit.Settings

      @base_name base_name_string

      @doc """
      Returns the base name, which identifies the process. For example it
      could be `posts`.
      """
      @spec base_name() :: String.t()
      def base_name, do: @base_name

      @doc """
      Returns the name, which identifies the process. It is composed using the
      `base_name/0` and the given `language`. For example if the `base_name/0`
      returns `posts` and the given language is `en`, the name will be
      `posts_en`.

      The worker id registered under the `Blogit.Components.Supervisor` will
      be the name returned by this function, when `start_link/1` is called
      to create the process. The language passed to it
      (or the one returned from `Blogit.Settings.default_language/0`) will be
      passed to `name/1` to create the name.
      """
      @spec name(String.t()) :: atom
      def name(language), do: :"#{base_name()}_#{language}"

      @doc """
      Starts the `GenServer` process.

      The process is started and supervised by `Blogit.Components.Supervisor`
      and the specification of it is added by `Blogit.Server`.

      The state of the process in the beginning is nil.

      The process should keep the given `language` passed to `init/1`
      as the first of a tuple as part of its state. This process should serve
      requests related to that `language`.

      The given `state_provider` is the second element of the tuple passed to
      `GenServer.init/1`. It could be used to retrieve the state of
      the process.

      By default the `language` is the one returned by
      `Blogit.Settings.default_language/0` and the `state_provider` is
      `Blogit.Server`.
      """
      @spec name(String.t()) :: GenServer.on_start()
      def start_link(
            language \\ Settings.default_language(),
            state_provider \\ Blogit.Server
          ) do
        args = {language, state_provider}
        GenServer.start_link(__MODULE__, args, name: name(language))
      end
    end
  end
end
