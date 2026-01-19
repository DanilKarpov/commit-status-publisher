<%@include file="/include-internal.jsp" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request" />
<bs:linkScript>
  /js/bs/changeLog.js
  /js/bs/changeLogGraph.js
  /js/raphael-min.js
  /js/bs/versionedSettings.js
</bs:linkScript>

<c:set var="changesPageUrl">
  <c:url value="${changesUrl}"/>
</c:set>

<et:subscribeOnEvents>
    <jsp:attribute name="eventNames">
      CHANGE_ADDED
    </jsp:attribute>
    <jsp:attribute name="eventHandler">
      $j('#versionedSettingsTabs').get(0).refresh();
    </jsp:attribute>
</et:subscribeOnEvents>

<bs:unprocessedMessages/>
<c:if test="${settingsBean.enabledGlobally}">
  <input type="button" class="btn btn_mini" onclick="BS.VersionedSettings.checkForChanges('${project.externalId}');" style="margin-top: 1em;"
         id="versionedSettingsCheckForChanges" value="Check for changes"/>
</c:if>
<div class="clr"></div>
<bs:refreshable containerId="versionedSettingsChangeLog" pageUrl="${changesPageUrl}">
  <c:if test="${not empty changeLogBean}">
    <bs:changesList
        changeLog="${changeLogBean}"
        url="${changesUrl}"
        filterUpdateUrl="/versionedSettingsChangeLogFilter.html?projectId=${project.externalId}"
        projectId="${project.externalId}"
        hideShowBuilds="true"
        hideBuildSelectors="true"/>
  </c:if>
</bs:refreshable>

