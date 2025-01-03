defmodule ExFiskal.RequestParams do
  alias ExFiskal.Enums.{PaymentMethod, SequenceMark}

  @base_tax_schema [:rate, :base, :amount]
  @other_tax_schema [:name | @base_tax_schema]

  @required_fields [
    :tax_number,
    :invoice_number,
    :business_unit,
    :device_number,
    :total_amount,
    :operator_tax_number
  ]

  @amount_fields [
    :total_amount,
    :vat_free_amount,
    :margin_amount,
    :non_taxable_amount
  ]

  @boolean_fields [
    :in_vat_system,
    :subsequent_delivery
  ]

  @tax_number_regex ~r/^\d{11}$/
  @invoice_number_regex ~r/^[1-9]\d*$/
  @business_unit_regex ~r/^[0-9a-zA-Z]+$/

  def new(params) when is_map(params) do
    params
    |> convert_amount_strings()
    |> ensure_boolean_values()
    |> set_defaults()
    |> validate()
    |> format_output()
  end

  def validate(params) do
    with {:ok, _} <- validate_required_fields(params),
         {:ok, _} <- validate_formats(params),
         {:ok, _} <- validate_arrays(params) do
      formatted_params = format_datetime_fields(params)
      {:ok, formatted_params}
    end
  end

  def validate_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        format_datetime_value(datetime)

      {:error, _} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive_dt} -> format_datetime_value(naive_dt)
          {:error, _} -> {:error, "invalid datetime format"}
        end
    end
  end

  def validate_datetime(%DateTime{} = dt), do: {:ok, format_datetime_value(dt)}
  def validate_datetime(%NaiveDateTime{} = dt), do: {:ok, format_datetime_value(dt)}
  def validate_datetime(_), do: {:error, "invalid datetime"}

  defp validate_required_fields(params) do
    missing_fields =
      Enum.filter(@required_fields, fn field ->
        is_nil(params[field]) || params[field] == ""
      end)

    case missing_fields do
      [] -> {:ok, params}
      fields -> {:error, missing_field_errors(fields)}
    end
  end

  defp validate_formats(params) do
    errors =
      %{}
      |> add_error(:tax_number, validate_tax_number(params.tax_number))
      |> add_error(:invoice_number, validate_invoice_number(params.invoice_number))
      |> add_error(:business_unit, validate_business_unit(params.business_unit))
      |> add_error(:device_number, validate_device_number(params.device_number))
      |> add_error(:total_amount, validate_amount(params.total_amount))
      |> add_error(:operator_tax_number, validate_tax_number(params.operator_tax_number))
      |> add_error(:payment_method, validate_payment_method(params[:payment_method]))
      |> add_error(:sequence_mark, validate_sequence_mark(params[:sequence_mark]))

    case Enum.empty?(errors) do
      true -> {:ok, params}
      false -> {:error, errors}
    end
  end

  defp validate_arrays(%{vat: vat} = params) when is_list(vat) do
    with :ok <- validate_tax_items(vat, @base_tax_schema),
         :ok <- validate_tax_items(params[:consumption_tax] || [], @base_tax_schema),
         :ok <- validate_tax_items(params[:other_taxes] || [], @other_tax_schema),
         :ok <- validate_fee_items(params[:fees] || []) do
      {:ok, params}
    else
      {:error, _} -> {:error, %{vat: "has invalid format"}}
    end
  end

  defp validate_arrays(params), do: {:ok, params}

  defp validate_tax_items(items, schema) do
    Enum.reduce_while(items, :ok, fn item, :ok ->
      case validate_tax_item(item, schema) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_tax_item(item, schema) do
    missing_keys = Enum.filter(schema, fn key -> !Map.has_key?(item, key) end)

    case missing_keys do
      [] -> validate_tax_item_formats(item)
      _ -> {:error, "Missing required fields: #{Enum.join(missing_keys, ", ")}"}
    end
  end

  defp validate_tax_item_formats(%{rate: rate, base: base, amount: amount} = item) do
    with :ok <- validate_rate(rate),
         :ok <- validate_amount(base),
         :ok <- validate_amount(amount) do
      if Map.has_key?(item, :name) do
        validate_name(item.name)
      else
        :ok
      end
    end
  end

  defp validate_fee_items(items) do
    Enum.reduce_while(items, :ok, fn item, :ok ->
      case validate_fee_item(item) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_fee_item(%{name: name, amount: amount}) do
    with :ok <- validate_name(name),
         :ok <- validate_amount(amount) do
      :ok
    end
  end

  defp validate_fee_item(_), do: {:error, "Fee item must have name and amount"}

  defp validate_tax_number(value) when is_binary(value) do
    if Regex.match?(@tax_number_regex, value), do: :ok, else: {:error, "has invalid format"}
  end

  defp validate_invoice_number(value) when is_binary(value) do
    if Regex.match?(@invoice_number_regex, value), do: :ok, else: {:error, "has invalid format"}
  end

  defp validate_business_unit(value) when is_binary(value) do
    if Regex.match?(@business_unit_regex, value), do: :ok, else: {:error, "has invalid format"}
  end

  defp validate_device_number(value) when is_binary(value) do
    if Regex.match?(@invoice_number_regex, value), do: :ok, else: {:error, "has invalid format"}
  end

  defp validate_amount(value) when is_integer(value), do: :ok

  defp validate_amount(_), do: {:error, "must be an integer representing cents"}

  defp validate_rate(value) when is_integer(value) do
    if value >= 0 and value <= 10000, do: :ok, else: {:error, "must be between 0 and 100%"}
  end

  defp validate_rate(_), do: {:error, "must be an integer representing percentage * 100"}

  defp validate_name(value) when is_binary(value) do
    if String.length(value) <= 100, do: :ok, else: {:error, "Name too long"}
  end

  defp validate_payment_method(nil), do: :ok

  defp validate_payment_method(value) when is_binary(value) do
    if value in PaymentMethod.values(), do: :ok, else: {:error, "has invalid value"}
  end

  defp validate_sequence_mark(nil), do: :ok

  defp validate_sequence_mark(value) when is_binary(value) do
    if value in SequenceMark.values(), do: :ok, else: {:error, "has invalid value"}
  end

  defp format_datetime_fields(params) do
    params
    |> format_field(:datetime)
    |> format_field(:invoice_datetime)
  end

  defp format_field(params, field) do
    case params[field] do
      %DateTime{} = dt -> Map.put(params, field, format_datetime_value(dt))
      %NaiveDateTime{} = dt -> Map.put(params, field, format_datetime_value(dt))
      _ -> params
    end
  end

  defp format_datetime_value(%DateTime{} = dt) do
    dt
    |> DateTime.to_naive()
    |> format_datetime_value()
  end

  defp format_datetime_value(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%d.%m.%Y") <> "T" <> Calendar.strftime(dt, "%H:%M:%S")
  end

  defp missing_field_errors(fields) do
    Enum.map(fields, fn field -> {field, "is required"} end)
    |> Map.new()
  end

  defp add_error(errors, _field, :ok), do: errors

  defp add_error(errors, field, {:error, message}) do
    Map.put(errors, field, message)
  end

  defp convert_amount_strings(params) do
    params
    |> Enum.map(fn
      {key, value} when key in @amount_fields ->
        case value do
          int when is_integer(value) -> {key, int}
          string when is_binary(string) -> {key, string_to_cents(string)}
          _ -> {key, value}
        end

      {key, value} ->
        {key, value}
    end)
    |> Map.new()
  end

  defp string_to_cents(string) when is_binary(string) do
    case Float.parse(string) do
      {float, _} -> trunc(float * 100)
      :error -> nil
    end
  end

  defp ensure_boolean_values(params) do
    params
    |> Enum.map(fn
      {key, value} when key in @boolean_fields ->
        {key, !!value}

      {key, value} ->
        {key, value}
    end)
    |> Map.new()
  end

  defp set_defaults(params) do
    now = NaiveDateTime.utc_now()

    defaults = %{
      message_id: UUID.uuid4(),
      datetime: now,
      invoice_datetime: now,
      in_vat_system: true,
      sequence_mark: SequenceMark.business_unit(),
      payment_method: PaymentMethod.cards(),
      subsequent_delivery: false,
      vat: [],
      consumption_tax: [],
      other_taxes: [],
      fees: [],
      vat_free_amount: nil,
      margin_amount: nil,
      non_taxable_amount: nil,
      paragon_number: nil,
      special_purpose: nil
    }

    Map.merge(defaults, params)
  end

  defp format_output({:ok, params}) do
    formatted_params =
      params
      |> format_amount_fields()
      |> format_tax_arrays()
      |> format_fee_array()

    {:ok, formatted_params}
  end

  defp format_output(error), do: error

  defp format_amount_fields(params) do
    Enum.reduce(@amount_fields, params, fn field, acc ->
      case Map.get(acc, field) do
        nil ->
          acc

        amount when is_integer(amount) ->
          Map.put(acc, field, cents_to_string(amount))

        _ ->
          acc
      end
    end)
  end

  defp format_tax_arrays(params) do
    params
    |> format_tax_array(:vat)
    |> format_tax_array(:consumption_tax)
    |> format_tax_array(:other_taxes)
  end

  defp format_tax_array(params, field) do
    case Map.get(params, field) do
      nil ->
        params

      items when is_list(items) ->
        formatted_items = Enum.map(items, &format_tax_item/1)
        Map.put(params, field, formatted_items)

      _ ->
        params
    end
  end

  defp format_tax_item(item) do
    item
    |> format_tax_amount(:base)
    |> format_tax_amount(:amount)
    |> format_tax_rate(:rate)
  end

  defp format_tax_amount(item, field) do
    case Map.get(item, field) do
      nil ->
        item

      amount when is_integer(amount) ->
        Map.put(item, field, cents_to_string(amount))

      _ ->
        item
    end
  end

  defp format_tax_rate(item, field) do
    case Map.get(item, field) do
      nil ->
        item

      rate when is_integer(rate) ->
        Map.put(item, field, rate_to_string(rate))

      _ ->
        item
    end
  end

  defp format_fee_array(params) do
    case Map.get(params, :fees) do
      nil ->
        params

      fees when is_list(fees) ->
        formatted_fees =
          Enum.map(fees, fn fee ->
            case fee do
              %{amount: amount} when is_integer(amount) ->
                %{fee | amount: cents_to_string(amount)}

              _ ->
                fee
            end
          end)

        Map.put(params, :fees, formatted_fees)

      _ ->
        params
    end
  end

  defp cents_to_string(cents) when is_integer(cents) do
    :erlang.float_to_binary(cents / 100.0, decimals: 2)
  end

  defp rate_to_string(rate) when is_integer(rate) do
    :erlang.float_to_binary(rate / 100.0, decimals: 2)
  end
end
