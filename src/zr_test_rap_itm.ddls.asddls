@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Items Test RAP'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZR_TEST_RAP_ITM
  as select from ztest_rap_itm
  
  association [0..1] to ZI_TEST_ITEM_TP as _Item
    on  $projection.ItemTypeID = _Item.ItemTypeID
  
  association to parent ZR_TEST_RAP as _Test // Relacion padre <-> hija
    on $projection.TravelUUID = _Test.TravelUUID
{
  key  ztest_rap_itm.item_uuid        as ItemUUID,
  key  ztest_rap_itm.travel_uuid      as TravelUUID,

  ztest_rap_itm.item_type            as ItemTypeID,

  @Semantics.amount.currencyCode: 'CurrencyCode'
  ztest_rap_itm.amount               as Amount,
  ztest_rap_itm.currency_code        as CurrencyCode,
  ztest_rap_itm.note                 as Note,

  @Semantics.user.createdBy: true
  ztest_rap_itm.local_created_by     as LocalCreatedBy,
  @Semantics.systemDateTime.createdAt: true
  ztest_rap_itm.local_created_at     as LocalCreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  ztest_rap_itm.local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  ztest_rap_itm.local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  ztest_rap_itm.last_changed_at      as LastChangedAt,

  /* Associations */
  _Item,
  
  _Test
}
