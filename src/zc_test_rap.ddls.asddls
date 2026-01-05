@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@Search.searchable: true
@EndUserText.label: 'Projection View for ZR_TEST_RAP'
define root view entity ZC_TEST_RAP
  provider contract transactional_query
  as projection on ZR_TEST_RAP
{
  key TravelUUID,
  
  @ObjectModel.text.element: ['TravelName']
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_TEST_TRAVEL', element: 'TravelID' },
                                       useForValidation: true }]
  TravelID,  
  
  @Semantics.text: true
  _Travel.TravelName as TravelName,

  @ObjectModel.text.element: ['CustomerName']  
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_TEST_CUSTOMER', element: 'CustomerID' },
                                       useForValidation: true }]
  CustomerID,
  
  @Semantics.text: true
  _Customer.CustomerName as CustomerName,
  BeginDate,
  EndDate,
  BookingFee,
  TotalPrice,  
  CurrencyCode,
@Search.defaultSearchElement: true
  Description,
  OverallStatus,
  LocalLastChangedAt,

  /* Associations */
 _Travel,
  
  _Items : redirected to composition child ZC_TEST_RAP_ITM
  
}
