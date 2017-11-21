defmodule Nerves.DnssdTest do
  use ExUnit.Case
  doctest Nerves.Dnssd, import: true

  def flush(), do: do_flush([])
  def flush(amount) when is_integer(amount) do
    do_flush([]) |> Enum.take(amount)
  end

  defp do_flush(acc) do
    receive do
      msg ->
        do_flush(acc ++ [msg |> strip_ref()])
    after
      1500 -> acc |> Enum.sort
    end
  end

  defp strip_ref({:dnssd, _ref, rest}), do: {:dnssd, :some_reference, rest}
  defp strip_ref(whatever), do: whatever

end
