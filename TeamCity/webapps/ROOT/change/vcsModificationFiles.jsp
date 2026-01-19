<%@ page import="jetbrains.buildServer.web.jsp.ChangeStatisticsPrinter" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="modification" scope="request" type="jetbrains.buildServer.vcs.SVcsModification"/>
<jsp:useBean id="buildTypeId" type="java.lang.String" scope="request"/>
<jsp:useBean id="changedFiles" type="java.util.List<jetbrains.buildServer.vcs.FilteredVcsChange>"
             scope="request"/>
<c:set var="statsText" value="<%= ChangeStatisticsPrinter.printFilesStatistics(changedFiles) %>"/>
<c:set var="modification" value="${filesTabModification}" scope="request"/>
<div class="changeHeader">
  <forms:saving id="changeBuildTypeProgress" className="progressRingInline" savingTitle="Filtering files according to checkout rules"/>
  Changed: ${statsText} in
  <select hidden name="buildTypeId" id="buildTypeId_changed">
    <option value="">&lt;All build configurations&gt;</option>
    <c:forEach var="entry" items="${relatedConfigurations}">
      <c:set var="buildType" value="${entry}"/>
      <c:if test="${buildType.personal}"><c:set var="buildType" value="${buildType.sourceBuildType}"/></c:if>
      <c:set var="modId" value="${modification.id}"/>
      <option value="buildTypeId=${buildType.externalId}&amp;filesTabModId=${modId}"
                    <c:if test="${buildTypeId == buildType.externalId}">selected="selected"</c:if>
                    data-build-type-id="${buildType.externalId}">
      </option>
    </c:forEach>
  </select>
  <div style="display: inline-block;">
    <div id="buildTypeId_changedSelect"></div>
  </div>
  <script>
    {
      const select = document.getElementById('buildTypeId_changed');
      const buildTypes = [...select.options].map(option => option.dataset.buildTypeId);
      const selected = buildTypes[select.selectedIndex];
      ReactUI.renderConnected('buildTypeId_changedSelect', ReactUI.ProjectBuildTypeSelect, {
        expandAll: true,
        projectsSelectable: false,
        allItemSelectable: true,
        allItemName: '<All build configurations>',
        includedBuildTypes: buildTypes,
        directions: [ReactUI.PopupDirections.BOTTOM_LEFT],
        selected: selected != null ? {nodeType: 'bt', id: selected} : {nodeType: 'all'},
        onSelect(item) {
          select.selectedIndex = item.nodeType === 'all' ? 0 : buildTypes.indexOf(item.id);
          BS.buildTypeIdChanged(select);
        }
      });
    }
  </script>
</div>
<div class="stamp stampMini">
  <dl class="changeExtensions">
    <ext:includeExtensions placeId="<%=PlaceId.CHANGE_DETAILS_BLOCK%>"/>
  </dl>
</div>
<div class="vcsModificationFilesList">
  <c:set var="buildType" value="${null}" scope="request"/>
  <bs:changedFiles changes="${changedFiles}" modification="${modification}"/>
</div>

<script type="text/javascript">
  if (BS.fixHeader) BS.fixHeader();
</script>