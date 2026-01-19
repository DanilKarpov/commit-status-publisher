<%@ include file="/include-internal.jsp" %><%@
    page import="jetbrains.buildServer.web.openapi.PlaceId" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %><%@
    taglib prefix="authz" tagdir="/WEB-INF/tags/authz" %><%@
    taglib prefix="ext" tagdir="/WEB-INF/tags/ext"

%><ext:includeExtensions placeId="<%=PlaceId.PROJECT_FRAGMENT%>" includeReactExtensions="true" />
<div id="toolbar" class="clearfix">
  <div class="toolbar-left">
    <bs:collapseExpand collapseAction="BS.CollapsableBlocks.collapseAll(true); return false" expandAction="BS.CollapsableBlocks.expandAll(true); return false"/>
    <div style="display: inline-block; width: 8px;"></div>
    <profile:booleanPropertyCheckbox propertyKey="overview.hideSuccessful"
                                     labelText="Hide successful configurations"
                                     afterComplete="BS.reload(true);"/>
  </div>
</div><jsp:include page="/projectBuildTypes.jsp"
/><jsp:include page="/_visibilityDialogs.jsp"
/><bs:executeOnce id="pauseDialog"><bs:pauseBuildTypeDialog/></bs:executeOnce>
