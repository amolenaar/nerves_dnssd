defmodule Nerves.DnssdTest do
  use ExUnit.Case
  doctest Nerves.Dnssd, import: true

  def flush(amount) when is_integer(amount) do
    flush([]) |> Enum.take(amount)
  end

  def flush(acc \\ []) do
    receive do
      msg ->
        flush(acc ++ [msg |> strip_ref()])
    after
      1500 -> acc |> Enum.sort
    end
  end

  defp strip_ref({:dnssd, _ref, rest}), do: {:dnssd, :some_reference, rest}
  defp strip_ref(whatever), do: whatever

end
