# ABAP RAP Travel & Expenses App (Draft + Actions + Validations)
Travel &amp; Expenses App built with ABAP RAP (OData V4 + Fiori Elements)

> Goal: showcase a clean RAP setup with **parent–child composition**, **instance actions (Approve/Reject)**, and **business validations**.


> ## What this app covers

### 1) Managed RAP BO with Draft (Header + Items)
- Parent entity (**Travel/Test**) with draft handling
- Child entity (**Items**) as a composition (header → items)
- Fiori elements UI facets: *General* + *Items list*

Links:
- Header (Projection View): **ZC_TEST_RAP** → _(add link)_  
- Header (BO / Root View Entity): **ZR_TEST_RAP** → _(add link)_  
- Item entity: **ZR_TEST_RAP_ITM** → _(add link)_
