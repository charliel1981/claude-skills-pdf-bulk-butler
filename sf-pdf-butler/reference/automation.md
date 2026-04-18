# Salesforce Automation — PDF Butler

All developer-facing APIs: Apex classes, LWC/Aura patterns, Flow invocables, Actionable interfaces, Process Builder hooks. Claude reads this for any PDF Butler code work.

---

## Global Apex classes exposed by `cadmus_core`

Full list from the external API reference at `eu1.pdfbutler.com/files/api/cadmuscore/`:

`AbstractAfterActionable`, `AbstractBeforeActionable`, `AbstractBeforeWithDataSourcesActionable`, `AbstractDataSourceActionable`, `Actionable_AutoEmail`, `Actionable_AutoEmail2`, `Actionable_AutoEmailQuickAction`, `Actionable_EmailDocConfigQuickAction`, `Actionable_PrepEmailDocConfig`, `Actionable_AdobeSign`, `Actionable_RunAfterFlow`, `Actionable_RunOnContentVersionFlow`, `CadmusHttpCalloutMock`, `CadmusHttpResponse`, `CadmusKeyValue`, `CadmusParameters`, `ComponentDataByFlowInput`, `ConvertController`, `ConvertInvocableWithReturnVariables`, `DocGenerationWrapper`, `DocumentDataHandler`, `DocxToPdfInvocable`, `ListWrapper`, `MetadataWrapper`, `PdfActions`, `PdfButlerCallable`, `RestDocConfigDynamicActionables`, `RestExportDocConfig`, `RestExportDocConfig2`, `RestExportPack`, `RestImportDocConfig`, `RestImportPack`, `RestManageAdmin`, `RestReportDataSource`, `RestTranslationEngine`, `SingleWrapper`, `UtilClasses`.

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
| `convertToDocx` | `webService static String convertToDocx(Id docConfigId, Id objectId)` | **Deprecated** |
| `convertToDocxAura` | `@AuraEnabled global static String convertToDocxAura(Id docConfigId, Id objectId)` | — |
| `convertToPdf` | `webService static String convertToPdf(Id docConfigId, Id objectId)` | **Deprecated** |
| `convertToPdfAura` | `@AuraEnabled global static String convertToPdfAura(Id docConfigId, Id objectId)` | **Deprecated** |
| `fileUploader` | `global static UtilClasses.FileUploadResponse fileUploader(List<UtilClasses.FileUploadData> datas)` | Upload files to external (e.g. SharePoint) |

**Rule**: always prefer `convertWithWrapper` for new code. The `convertTo*` helpers exist only for legacy callers.

### `ConvertController.ConvertDataModel` — every field

| Field | Type | Purpose |
|---|---|---|
| `objectId` | `Id` | **Required** — record the template runs against |
| `docConfigId` | `Id` | Required unless `packId` set |
| `packId` | `Id` | Required if no `docConfigId` |
| `docConfigIds` | `List<Id>` | Override Pack's DocConfig set; requires `packId` |
| `alternativeName` | `String` | Pick a DocConfig Alternative (localised/branded variant) |
| `language` | `String` | Translation language (auto-extracted from `locale` if unset) |
| `locale` | `String` | e.g. `en_US`, `de_DE` |
| `country` | `String` | DateTime formatting |
| `numCurrLocale` | `String` | Number/currency formatting (may differ from `locale`) |
| `timeZone` | `String` | DateTime formatting tz |
| `targetType` | `String` | `PDF` or `DOCX` (overrides DocConfig default) |
| `pdfActionType` | `String` | `MERGE` or `NONE` — controls Pack output merge |
| `mergeActions` | `PdfActions` | Object for more granular PDF merge settings |
| `deliveryOverwrite` | `String` | `BASE64`, `FILES`, `FILES_OVERWRITE` etc. |
| `inputMap` | `Map<String, Object>` | Arbitrary variables available to DataSources / Configs |
| `parameters` | `CadmusParameters` | Typed variables bag |

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

| Field | Type | Purpose |
|---|---|---|
| `result` | `String` | `SUCCESS` / `FAILED` |
| `response` | `CadmusHttpResponse` | Contains `.base64` (Blob) + `.metadata.targetName` (String) |
| `attachmentId` | `String` | Set when delivery = Attachment |
| `contentDocumentId` | `String` | Set when delivery = Files |
| `contentDocumentLinkId` | `String` | Set when delivery = Files |
| `contentVersionId` | `String` | Set when delivery = Files |
| `deliveryType` | `String` | Actual delivery after `deliveryOverwrite` applied |
| `uiActions` | `List<UtilClasses.KeyValue>` | Post-conversion UI actions (for LWC consumers) |

Always check `wrapper.result == 'SUCCESS'` before reading bytes.

---

## `cadmus_core.DocumentDataHandler` — file-level manipulation

Used inside Before Actionables to inject files into the document generation pipeline.

| Method | Purpose |
|---|---|
| `addDynamicFile(Id contentDocumentId)` | Merge a Salesforce File into output. Content pulled into Apex heap. |
| `addDynamicFileWithoutContent(Id contentDocumentId)` | Same, but backend pulls the content — **heap-safe**. Use for large merges. |
| `addDynamicAttachment(Id attachmentId)` | Merge a classic Attachment |
| `addDynamicBlob(String fileName, Blob pdf)` | Inject arbitrary PDF bytes (e.g. from a callout) |
| `addDocConfigOverride(ContentVersion, Id customerDocumentConfigId)` | Replace template at runtime |
| `addDocConfigOverride(Blob, Id customerDocumentConfigId)` | Same, binary variant |
| `generate(...)` | Lower-level generation entry — usually call `ConvertController` instead |

---

## Apex Actionable interfaces — lifecycle hooks

PDF Butler runs a pipeline: `BEFORE` → `DATA_SOURCE` → `BEFORE_BUT_AFTER_DATASOURCES` → **render** → `AFTER` → `ON_CONTENT_VERSION`. Each stage has its own interface.

### `AbstractBeforeActionable` — before anything runs

```apex
global void execute(
    cadmus_core__Actionable__c actionable,
    Id docConfig,
    Id objectId,
    Map<String, Object> inputMap,
    cadmus_core.ConvertController.ConvertDataModel cdm
)
```

**Actionable `When` field**: `BEFORE`
**Use for**: injecting files via `DocumentDataHandler`, seeding `inputMap`, callouts to external systems for data.

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
    Map<String, Object> inputMap, Map<String, Object> dsMap,
    cadmus_core.ConvertController.ConvertDataModel cdm
)
```

**Actionable `When` field**: `BEFORE_BUT_AFTER_DATASOURCES`
**`dsMap`** — DataSources keyed by **Customer DataSource Id**, values are `Map<String,Object>` (single) or `List<Map<String,Object>>` (list).

**Use for**: cross-DataSource calculations, conditional inputMap seeding based on fetched data.

```apex
global with sharing class PB_Act_YourCoolDataLogic
    implements cadmus_core.AbstractBeforeWithDataSourcesActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig, Id objectId,
            Map<String, Object> inputMap, Map<String, Object> dsMap,
            cadmus_core.ConvertController.ConvertDataModel cdm) {
        // DO YOUR CUSTOM LOGIC ON THE DATA HERE
    }
}
```

### `AbstractAfterActionable` — after doc created, before finalisation

Use for: post-generation callouts, custom delivery, updating the triggering record. Interface details in the external API ref.

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

**LWC template** — `generateDocument.html`:

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

## REST API (less common)

The package exposes REST endpoints via `RestDocConfigDynamicActionables`, `RestExportDocConfig`, `RestImportDocConfig`, `RestExportPack`, `RestImportPack`, `RestManageAdmin`, `RestReportDataSource`, `RestTranslationEngine`. Used primarily for migration tooling and external systems pulling generated docs.

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