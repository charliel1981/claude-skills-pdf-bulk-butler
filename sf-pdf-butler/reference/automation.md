# Salesforce Automation — PDF Butler

All developer-facing APIs: Apex classes, LWC/Aura patterns, Flow invocables, Actionable interfaces, Process Builder hooks. Claude reads this for any PDF Butler code work.

---

## Global Apex classes exposed by `cadmus_core`

**31 classes in the public ApexDoc reference** at `eu1.pdfbutler.com/files/api/cadmuscore/`:

`AbstractAfterActionable`, `AbstractBeforeActionable`, `AbstractBeforeWithDataSourcesActionable`, `Actionable_AutoEmail`, `Actionable_AutoEmail2`, `Actionable_PrepEmailDocConfig`, `CadmusHttpCalloutMock`, `CadmusHttpResponse`, `CadmusKeyValue`, `CadmusParameters`, `ComponentDataByFlowInput`, `ConvertController`, `ConvertInvocableWithReturnVariables`, `DocGenerationWrapper`, `DocumentDataHandler`, `DocxToPdfInvocable`, `ListWrapper`, `MetadataWrapper`, `PdfActions`, `PdfButlerCallable`, `RestDocConfigDynamicActionables`, `RestExportDocConfig`, `RestExportDocConfig2`, `RestExportPack`, `RestImportDocConfig`, `RestImportPack`, `RestManageAdmin`, `RestReportDataSource`, `RestTranslationEngine`, `SingleWrapper`, `UtilClasses`.

**Also referenced in Academy code samples but NOT in the public ApexDoc** (verify in-org via `SELECT Name FROM ApexClass WHERE NamespacePrefix='cadmus_core'` — they exist in the installed package; just not published on the ApexDoc site):

`AbstractDataSourceActionable`, `Actionable_AutoEmailQuickAction`, `Actionable_EmailDocConfigQuickAction`, `Actionable_AdobeSign`, `Actionable_RunAfterFlow`, `Actionable_RunOnContentVersionFlow`.

_Source: [cadmuscore API reference index](https://eu1.pdfbutler.com/files/api/cadmuscore/index.html) (31 classes). The additional 6 are named verbatim by Academy working code examples._

---

## `cadmus_core.ConvertController` — entry point

### Methods (verbatim signatures)

| Method | Signature | Notes |
|---|---|---|
| `convert` | `webService static String convert(ConvertDataModel data)` | Returns ContentVersionId or AttachmentId |
| `convertAura` | `@AuraEnabled global static String convertAura(ConvertDataModel data)` | For LWC/Aura — returns JSON string |
| `convertWithWrapper` | `webService static DocGenerationWrapper convertWithWrapper(ConvertDataModel data)` | **Default for server-side Apex** |
| `convertWithWrapperAndInputMap` | `global static DocGenerationWrapper convertWithWrapperAndInputMap(ConvertDataModel data, Map<String, Object> inputMap)` | Complex pre-built inputMap |
| `convertStandaloneDocToPDF` | `@AuraEnabled global static String convertStandaloneDocToPDF(String fileName, Blob document, String pdfAction)` | Convert a DOCX blob → PDF without DocConfig |
| `convertStandaloneDocToPDFV2` | `@AuraEnabled global static String convertStandaloneDocToPDFV2(String fileName, Blob document, String pdfAction, String packId, String locale, String alternativeName)` | V2 adds pack/locale/alt |
| `convertToDocx` | `webService static String convertToDocx(Id docConfigId, Id objectId)` | **Deprecated** — use `convertWithWrapper(data)` |
| `convertToDocxAura` | `@AuraEnabled global static String convertToDocxAura(Id docConfigId, Id objectId)` | Not marked deprecated on the ApexDoc page — still callable, but prefer `convertAura` |
| `convertToPdf` | `webService static String convertToPdf(Id docConfigId, Id objectId)` | **Deprecated** — use `convertWithWrapper(data)` |
| `convertToPdfAura` | `@AuraEnabled global static String convertToPdfAura(Id docConfigId, Id objectId)` | **Deprecated** — use `convertWithWrapper(data)` |
| `fileUploader` | `global static UtilClasses.FileUploadResponse fileUploader(List<UtilClasses.FileUploadData> datas)` | Upload files to external (e.g. SharePoint) |

**Rule**: always prefer `convertWithWrapper` for new code. The `convertTo*` helpers exist only for legacy callers.

_Source: [`ConvertController.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/ConvertController.html)._

### `ConvertController.ConvertDataModel` — every field

All fields are declared `webService` unless noted otherwise. `webService` fields are SOAP-consumable (directly visible to the partner API); `global`-only fields are Apex-only.

| Field | Visibility | Type | Purpose |
|---|---|---|---|
| `objectId` | `webService` | `Id` | **Required** — record the template runs against |
| `docConfigId` | `webService` | `Id` | Required when no `packId` / `docConfigIds` |
| `packId` | `webService` | `Id` | Required if no `docConfigId` |
| `docConfigIds` | `webService` | `List<Id>` | Override Pack's DocConfig set; requires `packId` |
| `alternativeName` | `webService` | `String` | Pick a DocConfig Alternative (localised/branded variant) |
| `language` | `webService` | `String` | Translation language (auto-extracted from `locale` if unset — e.g. `de_DE` → `de`) |
| `locale` | `webService` | `String` | e.g. `en_US`, `de_DE`, `fr_CA`, `fr_BE`, `de_AT` |
| `country` | `webService` | `String` | DateTime formatting only |
| `numCurrLocale` | `webService` | `String` | Number/currency formatting (may differ from `locale`) |
| `timeZone` | `webService` | `String` | DateTime formatting tz |
| `targetType` | `webService` | `String` | `PDF` or `DOCX` (overrides DocConfig default; only used for DOCX convert) |
| `pdfActionType` | `webService` | `String` | `MERGE` or `NONE` — controls Pack output merge |
| `deliveryOverwrite` | `webService` | `String` | `BASE64`, `FILES`, `FILES_OVERWRITE`, `FILES_ADD_VERSION`, `ATTACHMENTS`, `ATTACHMENTS_OVERWRITE` (verbatim from ApexDoc) |
| `parameters` | `webService` | `CadmusParameters` | Typed variables bag — see shape below |
| `inputMap` | **`global`** | `Map<String, Object>` | Apex-only — arbitrary variables + DataSources. Not exposed via SOAP |
| `mergeActions` | **`global`** | `PdfActions` | Apex-only — page numbers / title / watermark; see "PdfActions" below. Not exposed via SOAP |

_Source: [`ConvertController.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/ConvertController.html)._

### Canonical call

```apex
cadmus_core.ConvertController.ConvertDataModel cdm =
    new cadmus_core.ConvertController.ConvertDataModel();
cdm.objectId    = recordId;
cdm.docConfigId = docConfigId;
cadmus_core.DocGenerationWrapper wrapper =
    cadmus_core.ConvertController.convertWithWrapper(cdm);

Blob   bytes    = wrapper.response.base64;          // Blob, not a String
String fileName = wrapper.response.metadata.targetName;
```

---

## `cadmus_core.DocGenerationWrapper` — response shape

Public constructor: `global DocGenerationWrapper()` — synthesise fakes in unit tests.

| Field | Type | Purpose |
|---|---|---|
| `result` | `String` | `SUCCESS` / `FAILED` |
| `response` | `CadmusHttpResponse` | Contains `.base64` (Blob) + `.metadata` (MetadataWrapper) + issues + child results |
| `attachmentId` | `String` | Set when delivery = Attachment |
| `contentDocumentId` | `String` | Set when delivery = Files |
| `contentDocumentLinkId` | `String` | Set when delivery = Files |
| `contentVersionId` | `String` | Set when delivery = Files |
| `deliveryType` | `String` | Actual delivery after `deliveryOverwrite` applied |
| `uiActions` | `List<UtilClasses.KeyValue>` | Post-conversion UI actions (for LWC consumers) |

Always check `wrapper.result == 'SUCCESS'` before reading bytes.

_Source: [`DocGenerationWrapper.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/DocGenerationWrapper.html)._

### `cadmus_core.CadmusHttpResponse` — what lives inside `wrapper.response`

| Field | Annot. | Type | Purpose |
|---|---|---|---|
| `base64` | — | `Blob` | Rendered file bytes |
| `metadata` | — | `MetadataWrapper` | See "MetadataWrapper" below |
| `contentDocumentId` | — | `String` | Files delivery Id |
| `contentDocumentLinkId` | — | `String` | Files delivery Id |
| `contentVersionId` | — | `String` | Files delivery Id |
| `additionalDocs` | — | `List<ChildDocConfigResult>` | One per child DocConfig in a Pack |
| `issues` | — | `List<Issue>` | Server-side problems — inspect when `result != 'SUCCESS'` |
| `result` | `@AuraEnabled` | `String` | Mirrors wrapper.result for LWC consumers |
| `adminKey` / `userKey` / `key` | — / — / `@AuraEnabled` | `String` | Internal auth handles |
| `adminUserName` | `@AuraEnabled` | `String` | Admin tenant username |
| `allowedStages` | `@AuraEnabled` | `List<String>` | Stages the current credential may target |
| `encryptKey` | — | `String` | Payload encryption handle |

**Nested class `CadmusHttpResponse.ChildDocConfigResult`** (one per DocConfig in a Pack):

```apex
global String attachmentId
global Blob   base64
global String contentDocumentId
global String contentDocumentLinkId
global String contentVersionId
global String customerDocumentConfigId  // the source DocConfig Id
global Integer size
global String targetName
```

**Nested class `CadmusHttpResponse.Issue`**:

```apex
global String description
@AuraEnabled global String level
```

_Source: [`CadmusHttpResponse.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/CadmusHttpResponse.html)._

### `cadmus_core.MetadataWrapper` — what lives inside `wrapper.response.metadata`

Constructors: `global MetadataWrapper()`, `global MetadataWrapper(String targetName, String targetId)`.

**Instance properties** (15):

| Field | Type | Purpose |
|---|---|---|
| `targetName` | `String` | Generated filename (most-used field) |
| `targetId` | `String` | Triggering record Id |
| `targetType` | `String` | `PDF` / `DOCX` that was produced |
| `alternativeName` | `String` | Alternative used |
| `flattenType` | `FLATTEN_TYPE` enum | `NONE` / `REMOVE_CONFIG_ONLY` / `FULL_FLATTEN` |
| `isSandbox` | `Boolean` | True when called from a sandbox |
| `locale` | `CadmusLocale` | Resolved locale |
| `numCurrLocale` | `CadmusLocale` | Resolved number/currency locale |
| `organizationId` | `String` | SFDC Org Id |
| `pdfActionType` | `String` | `MERGE` / `NONE` |
| `stage` | `String` | Resolved Stage (`PROD`, `UAT`, `DEV1`, ...) — useful for debugging cross-stage issues |
| `usageType` | `USAGE_TYPE` enum | See enum values below |
| `userId` | `String` | Triggering SFDC User Id |
| `userType` | `String` | User type (Standard / Community / Guest / etc.) |
| `version` | `String` | PDF Butler version |

**Static mirror properties** (8 — runtime singletons, not constants): `alternativeNameStatic`, `deliveryTypeStatic`, `flattenTypeStatic`, `localeStatic`, `numCurrLocaleStatic`, `pdfActionTypeStatic`, `sfdcDatasourceStatic`, `targetTypeStatic`.

**Nested class `MetadataWrapper.CadmusLocale`**:

```apex
global String country
global String language
global String locale
global String timezone
```

**Enums**:

```apex
global enum MetadataWrapper.CALLED_FROM_TYPE_CUSTOMER {
    LIST_VIEW,
    APEX,
    AGENTFORCE      // PDF Butler is Agentforce-aware
}

global enum MetadataWrapper.FLATTEN_TYPE {
    NONE,
    REMOVE_CONFIG_ONLY,
    FULL_FLATTEN
}

global enum MetadataWrapper.USAGE_TYPE {
    NORMAL,
    COMMUNITY,
    BATCH,
    MASS_VOLUME,
    NORMAL_ASYNC,
    COMMUNITY_ASYNC,
    NORMAL_APEX,
    NORMAL_PDFB,
    AGENTFORCE      // set when invoked from an Agentforce action
}
```

_Source: [`MetadataWrapper.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/MetadataWrapper.html)._

### `cadmus_core.PdfActions` — page numbers, title, watermark

Object placed on `cdm.mergeActions` to drive built-in PDF post-processing. **This is the native, in-package replacement for the old `PB_AddPdfMergeActions` add-on class** — no support ticket needed.

| Field | Type | Purpose |
|---|---|---|
| `addPageNr` | `Boolean` | Render page numbers |
| `pageNrLocation` | `PdfActions.Location` enum | `TOP_RIGHT` / `TOP_LEFT` / `BOTTOM_RIGHT` / `BOTTOM_LEFT` |
| `pageNrPrefix` | `String` | Text before the page number (e.g. `"Page "`) |
| `pageNrXOffset` | `Integer` | Horizontal pixel offset |
| `pageNrYOffset` | `Integer` | Vertical pixel offset |
| `fontSize` | `Integer` | Font size for page number + title |
| `showTitle` | `Boolean` | Render a title on each page |
| `titleLocation` | `PdfActions.Location` enum | Same four corners as `pageNrLocation` |
| `titleXOffset` | `Integer` | Horizontal pixel offset for title |
| `titleYOffset` | `Integer` | Vertical pixel offset for title |
| `watermark` | `PdfActions.Watermark` enum | `NONE` / `DRAFT` / `CONFIDENTIAL` / `SAMPLE` — built-in stock watermarks |

```apex
cadmus_core.PdfActions actions = new cadmus_core.PdfActions();
actions.addPageNr       = true;
actions.pageNrLocation  = cadmus_core.PdfActions.Location.BOTTOM_RIGHT;
actions.pageNrPrefix    = 'Page ';
actions.watermark       = cadmus_core.PdfActions.Watermark.DRAFT;
cdm.mergeActions = actions;
```

_Source: [`PdfActions.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/PdfActions.html)._

### `cadmus_core.CadmusParameters` — typed variables for `cdm.parameters`

Both types carry `@JsonAccess(serializable='always' deserializable='always')` so they round-trip cleanly through Flow and JSON APIs.

```apex
global with sharing class CadmusParameters {
    global List<CadmusKeyValue> values;
}

global with sharing class CadmusKeyValue {
    @InvocableVariable(label='Unique Key for the value.')  global String  key;
    @InvocableVariable(label='String value')               global String  valueString;
    @InvocableVariable(label='Boolean value')              global Boolean valueBoolean;
    @InvocableVariable(label='Date value')                 global Date    valueDate;
    @InvocableVariable(label='DateTime value')             global DateTime valueDateTime;
    @InvocableVariable(label='Double value')               global Double  valueDouble;
    @InvocableVariable(label='Integer value')              global Integer valueInteger;
    // NOTE: `valueMultiSelect` is declared but lacks an @InvocableVariable annotation
    global String valueMultiSelect;
}
```

```apex
cadmus_core.CadmusKeyValue kv = new cadmus_core.CadmusKeyValue();
kv.key = 'DISCOUNT_PCT';
kv.valueDouble = 12.5;
cadmus_core.CadmusParameters params = new cadmus_core.CadmusParameters();
params.values = new List<cadmus_core.CadmusKeyValue>{ kv };
cdm.parameters = params;
```

Use `cdm.parameters` (typed) rather than `cdm.inputMap` (untyped) when the Flow / external caller needs introspection or a concrete Date / Boolean / Double type.

_Source: [`CadmusParameters.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/CadmusParameters.html), [`CadmusKeyValue.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/CadmusKeyValue.html)._

---

## `cadmus_core.DocumentDataHandler` — file-level manipulation

Used inside Before Actionables to inject files into the document generation pipeline. All methods are `global static`.

| Method | Signature | Purpose |
|---|---|---|
| `addDynamicFile` | `void addDynamicFile(Id contentDocumentId)` | Merge a Salesforce File into output. Content pulled into Apex heap. |
| `addDynamicFileWithoutContent` | `void addDynamicFileWithoutContent(Id contentDocumentId)` | Same, but backend pulls the content — **heap-safe**. Use for large merges. |
| `addDynamicAttachment` | `void addDynamicAttachment(Id attachmentId)` | Merge a classic Attachment |
| `addDynamicBlob` | `void addDynamicBlob(String fileName, Blob pdf)` | Inject arbitrary PDF bytes (e.g. from a callout) |
| `addDocConfigOverride` | `void addDocConfigOverride(ContentVersion cv, String customerDocumentConfigId)` | Replace template at runtime (file variant) |
| `addDocConfigOverride` | `void addDocConfigOverride(Blob base64, String customerDocumentConfigId)` | Replace template at runtime (binary variant) |
| `addPicklistDependency` | `void addPicklistDependency(String parentPicklist, String childPicklist, Map<String, List<String>> valueDependencies)` | Inject a picklist dependency when the runtime can't auto-detect one |
| `generate` | `DocGenerationWrapper generate(Id docConfigId, String targetId, Map<String, Object> inputMap)` | **Low-level** — does NOT run Actionables. Call `ConvertController` for the full pipeline |
| `generate` | `DocGenerationWrapper generate(List<Id> docConfigIds, String targetId, Map<String, Object> inputMap)` | Multi-DocConfig variant |
| `generate` | `DocGenerationWrapper generate(List<Id> docConfigIds, String targetId, Map<String, Object> inputMap, String jsonInput)` | Adds raw JSON input alongside `inputMap` |

**Public static property**: `global static String communityNetworkId` — set this inside a Before Actionable when generating documents in an Experience Cloud context that loses the network context otherwise.

Note on `addDocConfigOverride`: the second parameter type is `String customerDocumentConfigId` (not `Id`) — quote exactly as the ApexDoc declares.

_Source: [`DocumentDataHandler.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/DocumentDataHandler.html)._

---

## Apex Actionable interfaces — lifecycle hooks

PDF Butler runs a pipeline: `BEFORE` → `DATA_SOURCE` → `BEFORE_BUT_AFTER_DATASOURCES` → **render** → `AFTER` → `ON_CONTENT_VERSION`. Each stage has its own interface.

### `AbstractBeforeActionable` — before anything runs

```apex
global void execute(
    cadmus_core__Actionable__c actionable,   // The Actionable record with fields user can read
    Id docConfig,                            // Id of the DocConfig that was running
    Id objectId,                             // recordId of the record the request started on
    Map<String, Object> inputMap,            // fields used as parameters for SOQL DataSources.
                                             // recordId + userId always present.
    cadmus_core.ConvertController.ConvertDataModel cdm
)
```

**Actionable `When` field**: `BEFORE`
**Use for**: injecting files via `DocumentDataHandler`, seeding `inputMap`, callouts to external systems for data.

_Source: [`AbstractBeforeActionable.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/AbstractBeforeActionable.html)._

```apex
global with sharing class AddFileViaAPI implements cadmus_core.AbstractBeforeActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig,
            Id objectId, Map<String, Object> inputMap,
            cadmus_core.ConvertController.ConvertDataModel cdm) {
        cadmus_core.DocumentDataHandler.addDynamicFilewithoutcontent('069d1000001d4L3AAI');
    }
}
```

### `AbstractDataSourceActionable` — during DataSource resolution

```apex
global void execute(
    cadmus_core__Actionable__c actionable, Id docConfig, Id objectId,
    Map<String, Object> inputMap,
    cadmus_core.ConvertController.ConvertDataModel cdm,
    cadmus_core.UtilClasses.DataSourceActionableData dataSourceData
)
```

**Actionable `When` field**: `DATA_SOURCE`
**`dataSourceData` exposes**:
- `dataSourceList` — List of `cadmus_core__Data_Source__c`
- `dataSourceMap` — Map keyed by customer DataSource Id

**Use for**: mutating SOQL at runtime, e.g. replacing `::TOKEN` placeholders with per-request values.

```apex
global class Actionable_DataSourceUpdater implements cadmus_core.AbstractDataSourceActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig, Id objectId,
            Map<String, Object> inputMap, cadmus_core.ConvertController.ConvertDataModel cdm,
            cadmus_core.UtilClasses.DataSourceActionableData dataSourceData) {
        String order = (String) inputMap.get('sortOrder');
        if (String.isEmpty(order)) {
            Opportunity opp = [SELECT Product_Ordering__c FROM Opportunity WHERE Id = :objectId];
            order = opp.Product_Ordering__c;
        }
        for (cadmus_core__Data_Source__c ds : dataSourceData.dataSourceList) {
            ds.cadmus_core__SOQL__c = ds.cadmus_core__SOQL__c.replace('::ORDERING', order);
        }
    }
}
```

### `AbstractBeforeWithDataSourcesActionable` — after DSes populated, before render

```apex
global void execute(
    cadmus_core__Actionable__c actionable, Id docConfig, Id objectId,
    Map<String, Object> inputMap,
    Map<String, Object> dataSources,    // ApexDoc-canonical name; dsMap is a common local alias
    cadmus_core.ConvertController.ConvertDataModel cdm
)
```

**Actionable `When` field**: `BEFORE_BUT_AFTER_DATASOURCES`
**`dataSources`** — DataSources keyed by **Customer DataSource Id**, values are `Map<String,Object>` (single) or `List<Map<String,Object>>` (list).

**Use for**: cross-DataSource calculations, conditional inputMap seeding based on fetched data.

```apex
global with sharing class PB_Act_YourCoolDataLogic
    implements cadmus_core.AbstractBeforeWithDataSourcesActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig, Id objectId,
            Map<String, Object> inputMap, Map<String, Object> dataSources,
            cadmus_core.ConvertController.ConvertDataModel cdm) {
        // DO YOUR CUSTOM LOGIC ON THE DATA HERE
    }
}
```

_Source: [`AbstractBeforeWithDataSourcesActionable.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/AbstractBeforeWithDataSourcesActionable.html)._

### `AbstractAfterActionable` — after doc created, before finalisation

```apex
global void execute(
    cadmus_core__Actionable__c actionable,
    Id docConfig,
    Id objectId,
    Map<String, Object> inputMap,
    cadmus_core.ConvertController.ConvertDataModel cdm,
    cadmus_core.DocGenerationWrapper wrapper   // the rendered result — unique to After
)
```

**Actionable `When` field**: `AFTER`
**Use for**: post-generation callouts, custom delivery, updating the triggering record, forwarding the file anywhere. Only `AfterActionable` receives the finished `DocGenerationWrapper` — that's the defining reason to choose it over the Before variants.

```apex
global with sharing class PB_Act_FileToExternal
    implements cadmus_core.AbstractAfterActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig,
            Id objectId, Map<String, Object> inputMap,
            cadmus_core.ConvertController.ConvertDataModel cdm,
            cadmus_core.DocGenerationWrapper wrapper) {
        Blob bytes = wrapper.response.base64;
        // ...push to external system, etc.
    }
}
```

_Source: [`AbstractAfterActionable.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/AbstractAfterActionable.html)._

---

## Flow / Process Builder integration

### Invocable actions (available from Flow/PB)

- **Convert a DOCX to PDF** — see `reference/packs-actionables.md` for full I/O table
- **Convert DocConfig / Pack** (via `ConvertInvocableWithReturnVariables`) — call a full DocConfig/Pack from Flow

### Flow → PDF Butler reserved characters

In Flow formulas feeding PDF Butler, `:` and `|` are **reserved** — they split text into structured data internally. If your text legitimately contains them, wrap with `URLENCODE()` in the Flow formula and PDF Butler will decode at merge time.

### Flow introduced variables

Documented in an external PDF (`Flow Introduced Variables.pdf`) — content not available in HTML. Consult the PDF when a user asks "what variables does PDF Butler add to my Flow context".

### Calling a Flow from a PDF Butler After Actionable

**Actionable `Record Type`**: `Run Lightning Flow`
**Actionable class**: `cadmus_core.Actionable_RunAfterFlow`
**Flow API Name**: the target autolaunched Flow
**Flow input variables** (must be declared in the Flow with these exact names and types):

| Name | Type | Fields |
|---|---|---|
| `info` | Apex-defined `AfterActionableFlow_Info` | `docConfigId`, `recordId`, `packId`, `alternativeName`, `locale` |
| `leadingDocument` | Apex-defined `AfterActionableFlow_Document` | `fileName`, `contentVersionId`, `contentDocumentId`, `contentDocumentLinkId`, `attachmentId` |
| `additionalDocuments` | Collection of `AfterActionableFlow_Document` | same fields |

**Typical use**: update the triggering record, save the file to a different parent, post to Chatter.

### Calling a Flow on ContentVersion (before save)

**Actionable `Record Type`**: `Run Lightning Flow`
**Actionable class**: `cadmus_core.Actionable_RunOnContentVersionFlow`
**When**: `ON_CONTENT_VERSION`
**Flow input variables**:

| Name | Type | I/O |
|---|---|---|
| `info` | `cadmus_core__AfterActionableFlow_Info` | Input |
| `contentVersion` | `ContentVersion` (record) | **Input + Output** |

**Use for**: setting file Title, Description, custom fields on the ContentVersion before it commits.

---

## LWC integration

### Full working Quick Action example

**Apex wrapper** — `DocumentConvertController.cls`:

```apex
global with sharing class DocumentConvertController {
    @AuraEnabled
    global static Map<String,String> convert(String recordId, String docConfigId) {
        cadmus_core.ConvertController.ConvertDataModel cdm =
            new cadmus_core.ConvertController.ConvertDataModel();
        cdm.objectId    = recordId;
        cdm.docConfigId = docConfigId;
        cadmus_core.DocGenerationWrapper wrapper =
            cadmus_core.ConvertController.convertWithWrapper(cdm);
        Map<String,String> result = new Map<String,String>();
        result.put('title',  wrapper.response.metadata.targetName);
        result.put('base64', EncodingUtil.base64Encode(wrapper.response.base64));
        return result;
    }
}
```

**LWC template** — `generateDocument.html` (`lightning-record-picker` requires **API version 56.0+** / Winter '23):

```html
<template>
    <lightning-card title="Generate Document">
        <lightning-spinner if:true={spinner}></lightning-spinner>
        <div class="slds-p-horizontal_small">
            <lightning-record-picker object-api-name="cadmus_core__Doc_Config__c"
                label="Doc Configs" placeholder="Search Doc Configs..."
                display-info={displayInfo} value={docConfigId}
                onchange={handleRecordPickerChange}></lightning-record-picker>
        </div>
        <div slot="footer">
            <lightning-button label="Generate Document" onclick={runDocConfig}
                variant="brand"></lightning-button>
        </div>
    </lightning-card>
</template>
```

**LWC controller** — `generateDocument.js`:

```javascript
import { LightningElement, api } from 'lwc';
import Toast from 'lightning/toast';
import convert from '@salesforce/apex/DocumentConvertController.convert';

export default class GenerateDocument extends LightningElement {
    @api recordId;
    spinner = false;
    docConfigId;
    displayInfo = { primaryField: 'Name' };

    handleRecordPickerChange(event) {
        this.docConfigId = event.detail.recordId;
    }

    runDocConfig() {
        this.spinner = true;
        convert({ recordId: this.recordId, docConfigId: this.docConfigId })
            .then((result) => {
                const linkSource = `data:application/pdf;base64,${result.base64}`;
                const a = document.createElement('a');
                a.href = linkSource;
                a.download = result.title;
                a.click();
                a.remove();
                Toast.show({ label: 'Success', message: `${result.title} generated`,
                             mode: 'sticky', variant: 'success' }, this);
                this.spinner = false;
            })
            .catch(error => {
                Toast.show({ label: 'Cannot Generate Document',
                             message: JSON.stringify(error),
                             mode: 'sticky', variant: 'error' }, this);
                this.spinner = false;
            });
    }
}
```

**LWC meta** — `generateDocument.js-meta.xml`:

```xml
<?xml version="1.0"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Generate Document</masterLabel>
    <targets><target>lightning__RecordAction</target></targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordAction">
            <actionType>ScreenAction</actionType>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Aura previewer example

External only: `https://eu1.pdfbutler.com/aura_previewer_example.html`. Follows same pattern as LWC — Apex returns `{title, base64}`, client constructs `data:application/pdf;base64,...` URL and drives `<iframe>` or download anchor.

### LWC base64 gotcha

`wrapper.response.base64` is a **Blob** in Apex. Before returning to JS: `EncodingUtil.base64Encode(wrapper.response.base64)`. Skipping this serialises as `[object Blob]`.

---

## Button / URL / List-view integration

### Custom button (URL hack)

Details live in an external PDF (`PDF Butler via URL Button v1.pdf`). High-level: build a URL that hits a Visualforce page provided by the package with query params `docConfigId`, `objectId`.

### List-view bulk button

Lightning Mass Actions are **not supported** on invocable actions as of writing. Use an **sObject-specific Visualforce page** from the PDF Butler add-on package — contact `support@pdfbutler.com` for the package (pre-built for Account, Opportunity, etc.) or code snippets for custom objects.

---

## External image sources (SharePoint)

Requires **Collaboration Butler** configured (namespace `cadmus_una`). Pattern:

```apex
global class Actionable_getFilesFromSharePointFolder
        implements cadmus_core.AbstractBeforeActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig,
            Id objectId, Map<String, Object> inputMap,
            cadmus_core.ConvertController.ConvertDataModel cdm) {
        // Retrieve SharePoint contents:
        cadmus_una.CollabMSGraphClient.getSiteDrive();
        cadmus_una.CollabMSGraphClient.getDriveItemsByPath();
        cadmus_una.CollabMSGraphClient.getDriveItemByPath();
        // Populate inputMap with list of {FileName, FileURL} maps:
        inputMap.put(dss.Id, myMapsList);
    }
}
```

**DocConfig side**: use a `KEYVALUE` DataSource with `FileName` + `FileURL` fields, Picture config element points to it.

---

## Permission Set Groups

The package ships permission sets in the `cadmus_core` namespace. Query live org for exact names:

```sql
SELECT Name, Label FROM PermissionSet WHERE NamespacePrefix = 'cadmus_core'
```

PDF Butler's own guidance: **do not clone** the package permission sets — wrap them in a Permission Set Group per job function:

- **Admin PSG** — template builders (include admin-grade PS)
- **User PSG** — document generators (include user-grade PS)

Same guidance applies to sister packages: BULK Butler, Collaboration Butler, SIGN Butler.

---

## REST API

The package exposes nine `@RestResource` classes. Used primarily for migration tooling (the `@pdfbutler/migration-cli` npm package hits these) and external systems pulling generated docs.

| URL mapping | Class | HTTP verbs | Signature |
|---|---|---|---|
| `/DocConfig/DynamicActionables/*` | `RestDocConfigDynamicActionables` | `@HttpGet` | `String doGet()` |
| `/DocConfig/Export/*` | `RestExportDocConfig` | `@HttpGet` | `String doGet()` — v1, returns JSON body |
| `/DocConfig/Export2/*` | `RestExportDocConfig2` | `@HttpGet` | `void doGet()` — v2, writes to `RestContext.response` directly (streams) |
| `/DocConfig/Import/*` | `RestImportDocConfig` | `@HttpPost` | `void importDocConfig()` |
| `/DocConfig/ReportDataSource/*` | `RestReportDataSource` | `@HttpGet` | `String doGet()` |
| `/DocConfig/TranslationEngine/*` | `RestTranslationEngine` | `@HttpPost` | `String doPost()` |
| `/Manage/Admin/*` | `RestManageAdmin` | `@HttpPost`, `@HttpPut` | `void setUrlRegionStage()`, `void updateCredentials()` |
| `/Pack/Export/*` | `RestExportPack` | `@HttpGet` | `void doGet()` — streams |
| `/Pack/Import/*` | `RestImportPack` | `@HttpPost` | `void importPack()` |

**v1 vs v2 export**: `Export` returns a JSON body (easier to log/diff, heap-bound); `Export2` streams via `RestContext.response` (heap-safe for large DocConfigs). There is no `/Pack/Export2/*` equivalent. Prefer v2 for DocConfig migration.

Full base URL: `/services/apexrest` under the installed org. Callers authenticate with a Salesforce session (OAuth / Session Id).

_Sources: individual class pages under [`eu1.pdfbutler.com/files/api/cadmuscore/`](https://eu1.pdfbutler.com/files/api/cadmuscore/)._

---

## Cross-package integration — `PdfButlerCallable`

If your code lives in a different managed package and you can't (or don't want to) take a compile-time dependency on `cadmus_core`, use `Callable` dynamic dispatch.

```apex
global with sharing class PdfButlerCallable implements Callable {
    global Object call(String action, Map<String, Object> args);
    global class ExtensionMalformedCallException extends Exception {}
}
```

**Only documented action key**: `'convert'` — returns a `cadmus_core.DocGenerationWrapper`.

```apex
Type t = Type.forName('cadmus_core', 'PdfButlerCallable');
Callable pdf = (Callable) t.newInstance();

// Build ConvertDataModel dynamically or via cross-package type
cadmus_core.ConvertController.ConvertDataModel cdm =
    new cadmus_core.ConvertController.ConvertDataModel();
cdm.objectId    = recordId;
cdm.docConfigId = docConfigId;

Object out = pdf.call('convert', new Map<String, Object>{ 'cdm' => cdm });
cadmus_core.DocGenerationWrapper w = (cadmus_core.DocGenerationWrapper) out;
```

Use this pattern for:
- **ISV / AppExchange add-ons** that don't want a static dependency
- **Agentforce custom actions** dispatched across package boundaries
- **Optional dependencies** — feature works when PDF Butler is installed, compiles clean when it isn't

Failed calls (unsupported action, malformed args) throw `PdfButlerCallable.ExtensionMalformedCallException`.

_Source: [`PdfButlerCallable.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/PdfButlerCallable.html)._

---

## Unit testing — `CadmusHttpCalloutMock`

PDF Butler makes HTTP callouts to its rendering backend. Unit tests can't hit the real endpoint — use the package-supplied `HttpCalloutMock`.

```apex
@isTest
global with sharing class CadmusHttpCalloutMock implements HttpCalloutMock {
    global CadmusHttpCalloutMock(Integer code, String status, String body,
                                 String method, Map<String, String> responseHeaders,
                                 String endpoint);
    global HTTPResponse respond(HTTPRequest req);

    // "Use this method always" — sanctioned positive test path
    global static void setTestCalloutMockSuccess(String targetId);

    // Lower-level — "better not to use this one"
    global static void setTestCalloutMock(Integer code, String status, String body,
                                          String method,
                                          Map<String, String> responseHeaders,
                                          String endpoint);
}
```

**Canonical positive test**:

```apex
@isTest
private class DocumentConvertControllerTest {
    @isTest static void convert_happyPath() {
        Account a = new Account(Name='Acme'); insert a;

        // Seed the mock for a successful PDF Butler callout against this record
        cadmus_core.CadmusHttpCalloutMock.setTestCalloutMockSuccess(a.Id);

        Test.startTest();
        cadmus_core.ConvertController.ConvertDataModel cdm =
            new cadmus_core.ConvertController.ConvertDataModel();
        cdm.objectId    = a.Id;
        cdm.docConfigId = 'a05000000000001';   // any well-formed Id — mock doesn't hit the real one
        cadmus_core.DocGenerationWrapper w =
            cadmus_core.ConvertController.convertWithWrapper(cdm);
        Test.stopTest();

        System.assertEquals('SUCCESS', w.result);
    }
}
```

**Notes**:

- The class is annotated `@isTest` at the class level — cannot be instantiated in production Apex.
- `setTestCalloutMockSuccess(targetId)` internally wires `Test.setMock(HttpCalloutMock.class, ...)` with a realistic 200-response body that satisfies `convertWithWrapper`.
- For failure-path tests, use the raw `setTestCalloutMock(code, status, body, ...)` form to simulate 4xx/5xx or malformed bodies.

_Source: [`CadmusHttpCalloutMock.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/CadmusHttpCalloutMock.html)._

---

## Utility wrapper classes

Two helper wrappers are published, alongside nested types inside `UtilClasses`. Quoted exactly from ApexDoc.

### `cadmus_core.SingleWrapper` — single-record DataSource payload

```apex
global with sharing class SingleWrapper {
    global SingleWrapper();
    global Map<String, Object> data;   // KEYVALUE-style payload
    global Object sfdcData;            // raw sObject for this single row
    global String type;
}
```

### `cadmus_core.ListWrapper` — list-shaped DataSource payload

```apex
global with sharing class ListWrapper {
    global ListWrapper();
    global List<Map<String, Object>> data;   // KEYVALUE-style rows
    global List<Object> sfdcData;            // raw sObject rows
    global String type;
}
```

Use these instead of hand-rolled `Map<String, Object>` when seeding KEYVALUE DataSources from a Before Actionable — they document intent and match the shape the rendering backend expects.

### `cadmus_core.UtilClasses` — nested helpers

All classes nested; no outer-class fields or methods.

```apex
// Used by DataSource actionables to mutate queried DataSources
global class UtilClasses.DataSourceActionableData {
    global DataSourceActionableData(Map<Id, Data_Source__c> dataSourceMap);
    global Set<Id> dataSourceIds;
    global List<Data_Source__c> dataSourceList;
    global Map<Id, Data_Source__c> dataSourceMap;
}

// Payload for ConvertController.fileUploader(...)
global with sharing class UtilClasses.FileUploadData {
    global FileUploadData(String contentVersionIdIn, String uploadUrlIn);
    global String contentVersionId;
    global String uploadUrl;
}

// Return from ConvertController.fileUploader(...)
global with sharing class UtilClasses.FileUploadResponse {
    global FileUploadResponse();
    // (no fields documented on ApexDoc page — verify in-org if consuming)
}

// Simple key/value used in DocGenerationWrapper.uiActions
global with sharing class UtilClasses.KeyValue {
    global KeyValue(String keyIn, String valueIn);
    global String key;
    global String value;
}
```

_Sources: [`SingleWrapper.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/SingleWrapper.html), [`ListWrapper.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/ListWrapper.html), [`UtilClasses.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/UtilClasses.html)._

---

## Common failure modes

| Symptom | Root cause | Fix |
|---|---|---|
| `Apex heap size too large` during multi-file merge | `addDynamicFile` pulls content into heap | Switch to `addDynamicFileWithoutContent` + enable `Handle Files Via API` on DocConfig |
| Flow "Convert a DOCX to PDF" produces no file | Called from trigger without `Run Async = true` | Set `Run Async = true` |
| LWC gets `[object Blob]` text | Forgot `EncodingUtil.base64Encode` | Wrap the Blob before returning |
| Flow formula text truncated at `:` or `\|` | Reserved chars | Wrap in `URLENCODE()` in the formula |
| `DATA_SOURCE` actionable never fires | `When` field not set to `DATA_SOURCE`, or Actionable not Active | Check both; must be `Active = true` |
| `ON_CONTENT_VERSION` flow throws on Apex-defined input | Flow input var name mismatch | Must be `info` (type `cadmus_core__AfterActionableFlow_Info`) and `contentVersion` (type ContentVersion record) |
| SharePoint image retrieval fails | Collaboration Butler not configured | Set up `cadmus_una` package first |

---

_Sources: multiple Academy pages under [pdf-butler-salesforce-automation/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-salesforce-automation/) + the external API reference at [eu1.pdfbutler.com/files/api/cadmuscore/](https://eu1.pdfbutler.com/files/api/cadmuscore/)._