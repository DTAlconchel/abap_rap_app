@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Projection View for ZR_TEST_RAP'
define view entity ZC_TEST_RAP_ITM
  as projection on ZR_TEST_RAP_ITM
{
  key ItemUUID,
  key TravelUUID,
  
  @ObjectModel.text.element: ['ItemName']
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_TEST_ITEM_TP', element: 'ItemTypeID' },
                                       useForValidation: true }]
  ItemTypeID,
  
    @Semantics.text: true
  _Item.ItemName as ItemName,
  Amount,
  CurrencyCode,
  Note,

// Campos Donut - Total 100% 
  _Test.TotalPrice as TotalPriceForChart,

  LocalLastChangedAt,

  /* Associations */  
  _Item,

  _Test : redirected to parent ZC_TEST_RAP
  
}
