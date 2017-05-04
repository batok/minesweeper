defmodule Minesweeper do
  @moduledoc """
  Documentation for Minesweeper.
  """

  use Plug.Builder
  import Plug.Conn
  require Logger
  plug Plug.Logger
  plug :dispatch

  @ws_port Application.get_env(:minesweeper, :ws_port)
  @login_entry_point Application.get_env(:minesweeper, :login_entry_point)
  @start_game_entry_point Application.get_env(:minesweeper, :start_game_entry_point)
  @select_entry_point Application.get_env(:minesweeper, :select_entry_point)
  @score_entry_point Application.get_env(:minesweeper, :score_entry_point)
  @json "application/json"


  def start(_argv) do
    port = @ws_port
    "Starting Web app at port #{port}" |> Logger.info
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port
    :timer.sleep(:infinity)
  end

  def not_found(conn) do
    {:error, "invalid resource"}
  end

  def dispatch(conn, opts) do
    rp = conn.request_path
    login_entry_point = @login_entry_point
    start_game_entry_point = @start_game_entry_point
    select_entry_point = @select_entry_point
    score_entry_point = @score_entry_point
    local_request = 
    case conn.method do
      "GET" ->
        case rp do
          "/api/hello" -> {nil, :say_hi, @json, 500}
          ^login_entry_point -> {:nil, :login, nil, 500}
          ^start_game_entry_point -> {:nil, :start_game, nil, 500}
          ^select_entry_point -> {:nil, :select_square, nil, 500}
          ^score_entry_point -> {:nil, :score, nil, 500}
          _ ->
            "invalid rp #{inspect rp}" |> Logger.info 
            {:nil, :not_found, nil, 404}
        end
      _ ->
        Logger.info "invalid method"
        {:nil, :not_found, nil, 404}
    end
    
    {mod, func, type, err_number_if_any} = local_request
    
    mod1 = 
    if is_nil(mod) do
      __MODULE__
    else
      mod
    end
    
    type1 = 
    if is_nil(type) do
      "application/json"
    else
      type
    end

    {st, val} =
    case apply(mod1, func, [conn]) do
      {:ok, val} -> {200, val}  
      {:error, val} -> {err_number_if_any, val}
    end
    
    conn
    |> Plug.Conn.put_resp_content_type(type1)
    |> send_resp(st, val)
  end

  def qp(conn) do
    cn = Plug.Conn.fetch_query_params(conn)
    cn.params
  end

  def say_hi(conn) do
    {:ok, Poison.encode!(%{message: "hello world"})}
  end

  def login(%{"user" => user, "password" => password}, :web) do
    # validating user and password and returning a token
    # meanwhile as user=foo&password=bar
    Logger.info("user is #{user}")
    Logger.info("password is #{password}")
    users = %{"foo" => "bar"}
    if (users |> Map.get(user, nil)) == password do
      Logger.info("#{user}/#{password}")
      Poison.encode!(%{token: "mytoken"})
    else
      raise "invalid user"
    end
  end

  def login(_map, :web) do
    raise "invalid data"
  end

  def login(conn) do
    map = qp(conn) 
    "login/1 #{inspect map}" |> Logger.info
    val = map |> login(:web)
    Logger.info("#{inspect val}")
    {:ok, val}
    rescue
      e ->
        Logger.info("#{inspect e}")
        {:error, "error ocurred"}
  end

  defp token_valid?(token) do
    # check if token is valid maybe against a MapSet in an agent
    match?(token, "mytoken")
  end

  defp create_board(token) do
    #here the board is generated and stored in the agent
    #meanwhile this is just a sample
    "0,1,0,0,0;0,0,0,0;1,0,0,0"
  end

  def start_game(%{"token" => token, 
    "mines" => mines, "rows" => rows, "columns" => columns}, :web) do
    # returns a board
    # in a json with something like this. 
    # {board: "0,1,0,0,0;0,0,0,0;1,0,0,0"}  where ; is the row delimiter
    if token_valid?(token) do
      %{board: create_board(token), seconds: 0, mines: mines}
      |> Poison.encode! 
    else
      raise "invalid"
    end
  end

  def start_game(_map, :web) do
    raise "invalid data"
  end 

  def start_game(conn) do
    map = qp(conn) 
    "start_game/1 #{inspect map}" |> Logger.info
    val = map |> start_game(:web)
    Logger.info("#{inspect val}")
    {:ok, val}
    rescue
      e ->
        Logger.info("#{inspect e}")
        {:error, "error ocurred"}
  end

  defp update_board(token, x, y) do
    #here the selected square is updated in the board
    #and returns -1 if is a mine, 0, if nothing is near, 
    #and >0 meaning number of surrounding mines. 
    -1
  end


  defp get_score(token) do
    #sample data meanwhile
    seconds = 3
    mines = 1
    {seconds, mines}
  end

  def select_square(%{"token" => token, "x" => x, "y" => y}, :web) do
    if token_valid?(token) do
      what = update_board(token, x, y)
      {seconds, mines} = get_score(token) 
      %{seconds: seconds, mines: mines, square_value: what}
      |> Poison.encode!
    else
      raise "error"
    end
  end

  def select_square(_map, :web) do
    raise "error"
  end

  def select_square(conn) do
    map = qp(conn) 
    "select_square/1 #{inspect map}" |> Logger.info
    val = map |> select_square(:web)
    Logger.info("#{inspect val}")
    {:ok, val}
    rescue
      e ->
        Logger.info("#{inspect e}")
        {:error, "error ocurred"}
  end

  def score(conn) do
    map = qp(conn) 
    "score/1 #{inspect map}" |> Logger.info
    val = map |> score(:web)
    Logger.info("#{inspect val}")
    {:ok, val}
    rescue
      e ->
        Logger.info("#{inspect e}")
        {:error, "error ocurred"}
  end

  def score(%{"token" => token}, :web) do
    if token_valid?(token) do
      {seconds, mines} = get_score(token)
      %{seconds: seconds, mines: mines}
      |> Poison.encode!
    else
      raise "error"
    end

  end

  def score(_map, :web) do
    raise "error"
  end


  defp get_key(map) do
    :crypto.hash(:md5, Poison.encode!(map)) 
    |> Base.encode16
    |> String.to_atom
  end

  def set_cache(data, map) do
    key = get_key(map)
    Agent.start_link(fn -> data end, name: key)
    spawn_link __MODULE__, :delete_cache_key, [key]
    data
  end

  def delete_cache_key(key, time \\ 5_000) do
    :timer.sleep time
    if Process.whereis(key) != nil do
      Agent.stop(key)
      "Cache key #{key} deleted" |> Logger.info
    end
  end

  def map_cached(map) do
    key = get_key(map)
    if Process.whereis(key) == nil do
      nil
    else
      {:ok, 
        Agent.get(
          key, 
          fn val -> val end
        )
      }
    end
  end

  def test(:login) do 
    json = Poison.decode!(login(%{"user" => "foo", "password" => "bar"}, :web))
    Map.get(json, "token", nil)
  end

  def test(:start) do
    json = Poison.decode!(start_game(%{"token" => "mylogin", "mines" => 6, "rows" => 10, "columns" => 10}, :web))
  end


end
