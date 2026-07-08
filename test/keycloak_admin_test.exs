defmodule KeycloakAdminTest do
  use ExUnit.Case

  alias KeycloakAdmin.Client
  alias KeycloakAdmin.KcResponse
  alias KeycloakAdmin.Representations.User

  test "create_user marks non-empty email as verified" do
    payload = create_user_payload(%User{email: "test@example.com", username: "test"})

    assert payload["emailVerified"] == true
  end

  test "create_user does not mark empty email as verified" do
    payload = create_user_payload(%User{email: "", username: "test"})

    assert payload["emailVerified"] == false
  end

  defp create_user_payload(user) do
    if is_nil(Process.whereis(KcFinch)) do
      start_supervised!({Finch, name: KcFinch})
    end

    {:ok, listen_socket} =
      :gen_tcp.listen(0, [:binary, :inet, active: false, packet: :raw, reuseaddr: true])

    {:ok, port} = :inet.port(listen_socket)

    server =
      Task.async(fn ->
        {:ok, socket} = :gen_tcp.accept(listen_socket)
        request = read_http_request(socket)

        :gen_tcp.send(socket, "HTTP/1.1 201 Created\r\ncontent-length: 0\r\n\r\n")
        :gen_tcp.close(socket)
        :gen_tcp.close(listen_socket)

        request
      end)

    assert {:ok, %KcResponse{status: 201}} =
             Client.create_user("token", "http://127.0.0.1:#{port}", "test", user)

    server
    |> Task.await()
    |> request_body()
    |> Jason.decode!()
  end

  defp read_http_request(socket, acc \\ "") do
    {:ok, chunk} = :gen_tcp.recv(socket, 0, 1_000)
    acc = acc <> chunk

    case String.split(acc, "\r\n\r\n", parts: 2) do
      [headers, body] ->
        if byte_size(body) >= content_length(headers) do
          acc
        else
          read_http_request(socket, acc)
        end

      _ ->
        read_http_request(socket, acc)
    end
  end

  defp content_length(headers) do
    headers
    |> String.split("\r\n")
    |> Enum.find_value(0, fn header ->
      case String.split(header, ":", parts: 2) do
        [name, value] ->
          if String.downcase(name) == "content-length" do
            value |> String.trim() |> String.to_integer()
          end

        _ ->
          nil
      end
    end)
  end

  defp request_body(request) do
    [_headers, body] = String.split(request, "\r\n\r\n", parts: 2)
    body
  end
end
