@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED ZTEST_RAP'
define root view entity ZR_TEST_RAP
  as select from ztest_rap as Test
  
     association [0..1] to ZI_TEST_TRAVEL as _Travel
      on  $projection.TravelID = _Travel.TravelID

     association [0..1] to ZI_TEST_CUSTOMER as _Customer
      on  $projection.CustomerID = _Customer.CustomerID
  
  composition [0..*] of ZR_TEST_RAP_ITM as _Items // Relacion padre <-> hija
{
  key travel_uuid as TravelUUID,
  travel_id as TravelID,
  customer_id as CustomerID,
  begin_date as BeginDate,
  end_date as EndDate,
  @Semantics.amount.currencyCode: 'CurrencyCode'
  booking_fee as BookingFee,
  @Semantics.amount.currencyCode: 'CurrencyCode'
  total_price as TotalPrice,
  currency_code as CurrencyCode,
  description as Description,
  overall_status as OverallStatus,
  @Semantics.user.createdBy: true
  local_created_by as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  local_created_at as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
  
  /* Associations */
  _Travel,
  _Customer,
  
  _Items
}
