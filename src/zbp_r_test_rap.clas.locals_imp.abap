CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS validateItemsSum FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateItemsSum.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

**********************************************************************
* Valida que la suma total de los Items no supere el total del viaje
**********************************************************************
  METHOD validateItemsSum.

      " Leemos los items que vamos a guardar
      READ ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Item
          FIELDS ( TravelUUID Amount CurrencyCode )
          WITH CORRESPONDING #( keys )
        RESULT DATA(items_changed).

      IF items_changed IS INITIAL.
        RETURN.
      ENDIF.

      " Recuperamos el precio total del viaje
      READ ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Item BY \_Test
          FIELDS ( TravelUUID TotalPrice CurrencyCode )
          WITH CORRESPONDING #( items_changed )
        RESULT DATA(travels).

      " Leer todos los items del viaje usando %tky del Test (no TravelUUID)
      READ ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Test BY \_Items
          FIELDS ( TravelUUID Amount CurrencyCode )
          WITH VALUE #( FOR tr IN travels ( %tky = tr-%tky ) )
        RESULT DATA(all_items).

      " Sumar por viaje
      TYPES: BEGIN OF ty_sum,
               TravelUUID TYPE sysuuid_x16,
               SumAmount  TYPE ztest_rap_itm-amount,
             END OF ty_sum.
      DATA sums TYPE HASHED TABLE OF ty_sum WITH UNIQUE KEY TravelUUID.

      LOOP AT all_items ASSIGNING FIELD-SYMBOL(<ai>).
        READ TABLE sums ASSIGNING FIELD-SYMBOL(<s>) WITH KEY TravelUUID = <ai>-TravelUUID.
        IF sy-subrc <> 0.
          INSERT VALUE ty_sum( TravelUUID = <ai>-TravelUUID SumAmount = 0 ) INTO TABLE sums ASSIGNING <s>.
        ENDIF.
        <s>-SumAmount = <s>-SumAmount + <ai>-Amount.
      ENDLOOP.

      " Validamos y marcamos error en el item cambiado
      LOOP AT items_changed INTO DATA(ch).
        READ TABLE travels INTO DATA(tra) WITH KEY TravelUUID = ch-TravelUUID.
        READ TABLE sums   INTO DATA(sm) WITH KEY TravelUUID = ch-TravelUUID.

        IF sm-SumAmount > tra-TotalPrice.
          APPEND VALUE #( %tky = ch-%tky ) TO failed-item.
          APPEND VALUE #(
            %tky = ch-%tky
            %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-error
                       text     = 'The amount exceeds the trip total'
                     )
          ) TO reported-item.
        ENDIF.
      ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS LHC_TEST DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    METHODS:
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR Test
        RESULT result,

      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys
            REQUEST requested_features FOR Test
        RESULT result,

      Approve FOR MODIFY
            IMPORTING keys FOR ACTION Test~Approve RESULT result,
      Reject FOR MODIFY
            IMPORTING keys FOR ACTION Test~Reject RESULT result,
      validateCustomer FOR VALIDATE ON SAVE
            IMPORTING keys FOR Test~validateCustomer,
      validateTravel FOR VALIDATE ON SAVE
            IMPORTING keys FOR Test~validateTravel.
ENDCLASS.

CLASS LHC_TEST IMPLEMENTATION.
  METHOD GET_GLOBAL_AUTHORIZATIONS.
  ENDMETHOD.

**********************************************************************
* Método Aprovar:
* Modifica un registro y cambia el status "A - Approved"
**********************************************************************
  METHOD Approve.

*  Leer status
   READ ENTITIES OF zr_test_rap IN LOCAL MODE
    ENTITY Test
            FIELDS ( OverallStatus )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_data)
        FAILED DATA(failed_data)
        REPORTED DATA(reported_data).

*  Actualizar solo con las != A
   MODIFY ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Test
            UPDATE FIELDS ( OverallStatus )
            WITH VALUE #( FOR row IN lt_data WHERE ( OverallStatus <> 'A' )
                    ( %tky = row-%tky
                          OverallStatus = 'A' ) )
        FAILED DATA(failed_upd)
        REPORTED DATA(reported_upd).

*   Devolver el %self - Refresh UI
    READ ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Test
            ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    result = VALUE #( FOR row IN lt_result
                ( %tky   = row-%tky
                  %param = row ) ).

    if failed_data-test IS INITIAL.
         INSERT VALUE #(
              %tky = keys[ 1 ]-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-success
                       text     = 'Trip approved successfully'
                     )
            ) INTO TABLE reported-test.
    endif.



  ENDMETHOD.

**********************************************************************
* Método Rechazar:
* Modifica un registro y cambia el status "R - Rejected"
**********************************************************************
  METHOD Reject.

*  Leer status
   READ ENTITIES OF zr_test_rap IN LOCAL MODE
    ENTITY Test
            FIELDS ( OverallStatus )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_data)
        FAILED DATA(failed_data)
        REPORTED DATA(reported_data).

*  Actualizar solo aquellas que son vacías o no están aprobadas
   MODIFY ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Test
            UPDATE FIELDS ( OverallStatus )
            WITH VALUE #( FOR row IN lt_data WHERE ( OverallStatus <> 'A' AND  OverallStatus <> 'R' )
                    ( %tky = row-%tky
                          OverallStatus = 'R' ) )
        FAILED DATA(failed_upd)
        REPORTED DATA(reported_upd).

*   Devolver el %self - Refresh UI
    READ ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Test
            ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_result).

    result = VALUE #( FOR row IN lt_result
                ( %tky   = row-%tky
                  %param = row ) ).

    if failed_data-test IS INITIAL.
         INSERT VALUE #(
              %tky = keys[ 1 ]-%tky
              %msg = new_message_with_text(
                       severity = if_abap_behv_message=>severity-success
                       text     = 'Trip rejected successfully'
                     )
            ) INTO TABLE reported-test.
    endif.

  ENDMETHOD.

**********************************************************************
* Habilita / Deshabilita dependiendo del valor Status
**********************************************************************
  METHOD GET_INSTANCE_FEATURES.

*   Leemos para habilitar / deshabilitar
    READ ENTITIES OF zr_test_rap IN LOCAL MODE
        ENTITY Test
            FIELDS ( OverallStatus TotalPrice )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_test)
        FAILED DATA(failed_test)
        REPORTED DATA(reported_test).

*   Para cada instancia: si ya está aprobado o rechazado no habilitamos el botón
    result = VALUE #( FOR row IN lt_test
                ( %tky = row-%tky
                  %features-%action-Approve = COND #(
                                                  WHEN ( row-OverallStatus = 'A' OR row-OverallStatus = 'R' )
                                                    THEN if_abap_behv=>fc-o-disabled
                                                  ELSE
                                                         if_abap_behv=>fc-o-enabled )

                  %features-%action-Reject = COND #(
                                                  WHEN ( row-OverallStatus = 'R' OR row-OverallStatus = 'A' )
                                                    THEN if_abap_behv=>fc-o-disabled
                                                  ELSE
                                                         if_abap_behv=>fc-o-enabled )
                  ) ).

  ENDMETHOD.

**********************************************************************
* Valida el ID de los Customer
**********************************************************************
  METHOD validateCustomer.

    DATA customers TYPE SORTED TABLE OF ztest_rap_cust WITH UNIQUE KEY customer_id.

" Read relevant travel instance data
    READ ENTITIES OF zr_test_rap IN LOCAL MODE
    ENTITY Test
     FIELDS ( CustomerID )
     WITH CORRESPONDING #(  keys )
    RESULT DATA(travels).

    " Optimization of DB select: extract distinct non-initial customer IDs
    customers = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING customer_id = CustomerID EXCEPT * ).
    DELETE customers WHERE customer_id IS INITIAL.
    IF customers IS NOT INITIAL.

      " Check if customer ID exists
      SELECT FROM ztest_rap_cust FIELDS customer_id
        FOR ALL ENTRIES IN @customers
        WHERE customer_id = @customers-customer_id
        INTO TABLE @DATA(customers_db).
    ENDIF.
    " Raise msg for non existing and initial customer id
    LOOP AT travels INTO DATA(travel).
      IF travel-CustomerID IS INITIAL
         OR NOT line_exists( customers_db[ customer_id = travel-CustomerID ] ).

        APPEND VALUE #(  %tky = travel-%tky ) TO failed-test.
        APPEND VALUE #(  %tky = travel-%tky
                         %msg      = new_message_with_text(
                                       severity = if_abap_behv_message=>severity-error
                                       text     = |Customer { travel-CustomerID } no existe|
                                     )
                      ) TO reported-test.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.

**********************************************************************
* Valida el ID de los Viajes
**********************************************************************
  METHOD validateTravel.

    DATA travelsname TYPE SORTED TABLE OF ztest_rap_travel WITH UNIQUE KEY travel_id.

" Read relevant travel instance data
    READ ENTITIES OF zr_test_rap IN LOCAL MODE
    ENTITY Test
     FIELDS ( TravelID )
     WITH CORRESPONDING #(  keys )
    RESULT DATA(travels).

    " Optimization of DB select: extract distinct non-initial travel IDs
    travelsname = CORRESPONDING #( travels DISCARDING DUPLICATES MAPPING travel_id = TravelID EXCEPT * ).
    DELETE travelsname WHERE travel_id IS INITIAL.
    IF travelsname IS NOT INITIAL.

      " Check if travels ID exists
      SELECT FROM ztest_rap_travel FIELDS travel_id
        FOR ALL ENTRIES IN @travelsname
        WHERE travel_id = @travelsname-travel_id
        INTO TABLE @DATA(travels_db).
    ENDIF.
    " Raise msg for non existing and initial travel id
    LOOP AT travels INTO DATA(travel).
      IF travel-TravelID IS INITIAL
         OR NOT line_exists( travels_db[ travel_id = travel-TravelID ] ).

        APPEND VALUE #(  %tky = travel-%tky ) TO failed-test.
        APPEND VALUE #(  %tky = travel-%tky
                         %msg      = new_message_with_text(
                                       severity = if_abap_behv_message=>severity-error
                                       text     = |Travel { travel-TravelID } no existe|
                                     )
                      ) TO reported-test.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
