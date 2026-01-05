# ABAP RAP Travel & Expenses App (Draft, Actions, Validations, Value Helps, Chart)

Demo app built with **SAP ABAP RAP** and exposed via **OData V4** for **Fiori elements**.
The app manages **Travels** (header) and **Expenses/Items** (child) with a draft-enabled transactional BO, value helps, validations, instance actions (Approve/Reject), and a donut chart.

> [!NOTE]
> The backend is stored using the standard **abapGit** format (`/src` + `.abapgit.xml`), so the code is easy to import/export and browse in GitHub.

---

## 🎥 Demo video

### Option A (recommended): GitHub Assets link
1. Create an Issue (you can close it later).
2. Drag & drop your `demo.mp4` into the comment.
3. GitHub will generate an **assets URL**.
4. Paste it here:

- **Demo walkthrough (MP4):** <PASTE_ASSETS_URL_HERE>

### Option B: Store video in the repo (only if small)
Place it under `docs/demo.mp4` and add:

- [Watch the demo video](RAP_APP_ABAP.mp4)

> [!TIP]
> If you want a nice preview, add an image thumbnail and link it to the MP4:
> `[![Demo](docs/demo_thumbnail.png)](docs/demo.mp4)`

---

## What this app covers

### 1) Parent–Child Model (Header → Items) with Composition
The business object is built around a **root entity** (Travel) and a **child entity** (Items).  
The child is modeled as a **composition**, meaning items belong to one travel and follow its lifecycle (draft, activation, locks, etc.).

- Root (Travel/Test): [`ZR_TEST_RAP`](src/zr_test_rap.ddls.asddls)
- Child (Items): [`ZR_TEST_RAP_ITM`](src/zr_test_rap_itm.ddls.asddls)
- Projection views (what the service exposes):
  - Header projection: [`ZC_TEST_RAP`](src/zc_test_rap.ddls.asddls)
  - Item projection: [`ZC_TEST_RAP_ITM`](src/zc_test_rap_itm.ddls.asddls)

In the projection view you can also see the redirected composition to items:  
- `_Items redirected to composition child`: [`ZC_TEST_RAP`](src/zc_test_rap.ddls.asddls#L36-L41)

---

### 2) Draft-enabled Transactional Behavior (Create/Update/Delete + Draft)
This app uses **managed RAP with draft** so users can:
- Create/Change data in draft
- Validate on save
- Activate/discard/resume drafts
- Get consistent locking + etag handling

Root Behavior Definition (draft, validations, actions, etag, locks):  
- [`ZR_TEST_RAP.bdef`](src/zr_test_rap.bdef.asbdef#L1-L56)

Key parts:
- ETag + lock master configuration: [`etag master / lock master`](src/zr_test_rap.bdef.asbdef#L8-L10)
- Draft actions: [`Edit/Activate/Discard/Resume`](src/zr_test_rap.bdef.asbdef#L48-L51)
- Draft Prepare (where validations are orchestrated): [`Prepare`](src/zr_test_rap.bdef.asbdef#L52-L55)

> [!IMPORTANT]
> In Fiori elements, an action can appear in the UI but behave incorrectly if it is not properly exposed in the projection behavior.
> Your projection behavior explicitly exposes both actions:
> - [`use action Approve/Reject`](src/zc_test_rap.bdef.asbdef#L13-L14)

---

### 3) Search & Filters (List Report)
The List Report supports searching and filtering.  
In your header projection, the **Description** is configured as the default search element:

- `@Search.defaultSearchElement`: [`ZC_TEST_RAP`](src/zc_test_rap.ddls.asddls#L31-L33)

This makes the UI “feel like an app” instead of a raw table viewer.

---

### 4) Value Helps (F4) + Text Associations
This app uses value helps so users don’t need to remember IDs.

#### 4.1 TravelID and CustomerID value helps (Header)
- Travel value help: `ZI_TEST_TRAVEL`
- Customer value help: `ZI_TEST_CUSTOMER`

Where they are wired (with `useForValidation: true`):
- [`TravelID value help`](src/zc_test_rap.ddls.asddls#L11-L18)
- [`CustomerID value help`](src/zc_test_rap.ddls.asddls#L19-L26)

Interface views:
- [`ZI_TEST_TRAVEL`](src/zi_test_travel.ddls.asddls)
- [`ZI_TEST_CUSTOMER`](src/zi_test_customer.ddls.asddls)

#### 4.2 ItemTypeID value help (Items)
- Wired in item projection: [`ZC_TEST_RAP_ITM`](src/zc_test_rap_itm.ddls.asddls#L10-L16)
- Value help entity: [`ZI_TEST_ITEM_TP`](src/zi_test_item_tp.ddls.asddls)

---

### 5) Validations on Save (Business Rules)
Validations are executed on save (and also during draft prepare), giving immediate feedback to the user.

#### 5.1 Validate CustomerID exists (Root)
- Defined in BDEF: [`validateCustomer`](src/zr_test_rap.bdef.asbdef#L40-L40)
- Implemented in handler: [`validateCustomer`](src/zbp_r_test_rap.clas.locals_imp.abap#L236-L274)

#### 5.2 Validate TravelID exists (Root)
- Defined in BDEF: [`validateTravel`](src/zr_test_rap.bdef.asbdef#L41-L41)
- Implemented in handler: [`validateTravel`](src/zbp_r_test_rap.clas.locals_imp.abap#L279-L316)

#### 5.3 Validate sum(Items) <= TotalPrice (Draft-aware)
Business rule: the total of expense items cannot exceed the travel total.

- Defined on Item entity: [`validateItemsSum`](src/zr_test_rap.bdef.asbdef#L108-L108)
- Executed via draft prepare: [`Prepare triggers Item~validateItemsSum`](src/zr_test_rap.bdef.asbdef#L52-L55)
- Implementation: [`validateItemsSum`](src/zbp_r_test_rap.clas.locals_imp.abap#L15-L74)

What’s interesting here: the validation is written to be **draft-aware** and takes into account the transactional buffer while saving.

> [!WARNING]
> If validations “miss” newly created draft records, it is usually because the READ pattern is reading only active data.
> Your implementation reads through associations in local mode, which is the right idea for draft scenarios.

---

### 6) Instance Actions (Approve / Reject) + Feature Control
The Travel can be approved or rejected using instance actions.
- **Approve** sets `OverallStatus = 'A'`
- **Reject** sets `OverallStatus = 'R'`

Actions are defined in the root behavior:
- [`Reject + Approve actions`](src/zr_test_rap.bdef.asbdef#L44-L45)

They are exposed in the projection behavior (mandatory for proper UI behavior):
- [`use action Approve/Reject`](src/zc_test_rap.bdef.asbdef#L13-L14)

#### 6.1 Action implementation
- [`Approve implementation`](src/zbp_r_test_rap.clas.locals_imp.abap#L109-L152)
- [`Reject implementation`](src/zbp_r_test_rap.clas.locals_imp.abap#L158-L199)

Each action returns `$self` so the UI refreshes immediately:
- You can see the result filling in the same methods.

#### 6.2 Dynamic enable/disable (get_instance_features)
Buttons are enabled only when it makes sense:
- If status is `A` or `R`, both actions are disabled.
- If status is initial, actions are enabled.

- [`GET_INSTANCE_FEATURES`](src/zbp_r_test_rap.clas.locals_imp.abap#L204-L231)

#### 6.3 UI placement (List Report toolbar buttons)
Actions are placed as list report buttons via UI annotations:
- [`FOR_ACTION Approve/Reject`](src/zc_test_rap.ddlx.asddlxs#L59-L60)

> [!IMPORTANT]
> If a button appears but only one behaves correctly, double-check the projection behavior includes `use action ...`.
> You already discovered this gotcha, and it’s one of the most common RAP/Fiori pitfalls.

---

### 7) Donut Chart on Items (Share visualization)
Items include a donut chart showing the distribution of expenses.

- Chart annotation: [`ZC_TEST_RAP_ITM.ddlx`](src/zc_test_rap_itm.ddlx.asddlxs#L3-L33)
- The chart compares `Amount` against a target coming from the parent:
  - `TotalPriceForChart` is pulled from `_Test.TotalPrice`:
  - [`TotalPriceForChart`](src/zc_test_rap_itm.ddls.asddls#L22-L22)

This is a nice Fiori elements touch because it gives meaning to the numbers without custom UI code.

---

### 8) OData V4 Exposure (Service Definition + Binding)
The app is exposed as an OData V4 service.

Service definition:
- [`ZUI_TEST_RAP_O4.srvd`](src/zui_test_rap_o4.srvd.srvdsrv)

Service binding:
- [`ZUI_TEST_RAP_O4.srvb.xml`](src/zui_test_rap_o4.srvb.xml)

---

## Repository structure
- `src/` ABAP objects serialized by abapGit
- `.abapgit.xml` repository descriptor
- `docs/` (recommended) screenshots + demo video

---

## How to run (high level)
1. Import into an ABAP system using abapGit
2. Activate all objects (CDS + behavior + handler class)
3. Publish the **Service Binding** (OData V4)
4. Launch the Fiori preview
5. Test:
   - Create a travel + items (draft)
   - Exceed total → validation error
   - Approve/Reject → status changes + action enablement rules

---

## TODO / Next improvements
- Add authorization checks for actions (Approve/Reject)
- Add currency consistency checks or currency conversion
- Enhance chart with percent labels or grouping by item type
- Add date validations (BeginDate <= EndDate)
