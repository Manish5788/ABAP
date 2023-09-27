@AbapCatalog.sqlViewName: 'ZCDS_FOSL_DEMOA1'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'CDS DEMO FOR FOSL'
define view ZCDS_FOSL_DEMOA as select from /dmo/flight 
{
    key carrier_id as CarrierId,
    key connection_id as ConnectionId,
    key flight_date as FlightDate,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    price as Price,
    //arithmetic expression 
    rtrim(plane_type_id,'4') as wtrim,
    //abap.decfloat16'12.09E5'        as float,
    //cast expression
    cast(price as abap.fltp) * 0.03 as checkAmpunt,
    currency_code as CurrencyCode,
    case  currency_code
    
          when 'USD' then 'DOLLAR'
          when 'EUR' then 'EURO'
          else 'NO IDEA'
    end as CurrencyType,
    coalesce(currency_code, connection_id) as wdesc,
    plane_type_id as PlaneTypeId,
    seats_max as SeatsMax,
    seats_occupied as SeatsOccupied,
    $session.user_timezone as userTime
} where carrier_id = 'SQ'
