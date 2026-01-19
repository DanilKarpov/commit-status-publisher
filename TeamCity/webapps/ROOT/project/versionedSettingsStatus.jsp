<%@include file="/include-internal.jsp" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request" />
<jsp:useBean id="settingsBean" type="jetbrains.buildServer.controllers.project.VersionedSettingsBean" scope="request"/>

<style type="text/css">
  div#versionedSettingsStatus {
    margin-top: 2em;
    margin-left: 1em;
  }
  .configErrors {
    margin-left: 1em;
  }
  span.configFile {
    font-weight: bold;
  }
  span.configFileErrorMessage {
    color: #a90f1a;
    white-space: pre;
  }

  div#versionedSettingsStatus table td {
    vertical-align: top;
  }
</style>
<c:set var="statusUrl">
  <c:url value="/versionedSettingsStatus.html?projectId=${project.externalId}"/>
</c:set>
<bs:refreshable containerId="versionedSettingsStatus" pageUrl="${statusUrl}">
  <c:set var="status" value="${settingsBean.status}"/>
  <c:choose>
    <c:when test="${not empty status}">
      <a name="status"></a>
      <h3>Current Status:</h3>
      <table>
        <tr>
          <td>
            <span>[<bs:date value="${status.timestamp}" pattern="${status.dateFormat}"/>]:</span>
          </td>
          <td>
            <c:if test="${status.warn}">
              <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
            </c:if>
            <span class="statusDescription" id="statusDescriptionText"><bs:out value="${status.description}" globalTransformationsOnly="true"/></span> <bs:copy2ClipboardLink dataId="statusDescriptionText" stripTags="true"/>
          </td>
        </tr>
        <tr>
          <td></td>
          <td id="configErrorsText">
            <c:if test="${not empty status.configErrors}">
              <c:forEach var="configError" items="${status.configErrors}">
                <div style="margin-left: 20px;">
                  <c:if test="${configError.filePathPresent}">
                    <span class="configFile"><c:out value="${configError.filePath}"/>:</span>
                  </c:if>
                  <span class="configFileErrorMessage"><c:out value="${configError.message}"/></span>
                </div>
                <c:if test="${configError.hasStackTrace}">
                  <div class="grayNote" style="margin-left: 20px;">
                    <c:forEach var="stackElement" items="${configError.stackTrace}"><c:out value="${stackElement}" /><br/></c:forEach>
                  </div>
                </c:if>
              </c:forEach>
              <div style="margin-top: .5em">
                The server will use last known good settings
                <c:if test="${!settingsBean.settingsRevision.equals('unknown')}">(revision <c:out value="${ settingsBean.settingsRevision }" />)</c:if>
                <bs:copy2ClipboardLink dataId="configErrorsText" stripTags="true"/>
              </div>
            </c:if>
            <c:if test="${fn:length(status.requiredContextParameters) != 0}">
              <div style="margin-top: .5em;">
                  <a href="<c:url value="${settingsBean.dslParametersTabUrl}"/>">Specify required DSL parameters</a>
              </div>
            </c:if>
          </td>
        </tr>
        <c:set var="effectiveSettings" value="${settingsBean.effectiveParentSettings}"/>
        <c:set var="definingProject" value="${empty effectiveSettings ? project : effectiveSettings.project}"/>
        <c:if test="${not status.warn and empty status.configErrors and not empty definingProject and status.dslOutdated}">
          <tr>
            <td></td>
            <td style="padding-top: 10px">
              <bs:buildStatusIcon type="red-sign" className="warningIcon"/>DSL scripts should be
              <admin:healthStatusReportLink project="${definingProject}" selectedCategory="outdatedProjectSettingsHealthCategory" minSeverity="WARN">updated</admin:healthStatusReportLink>
            </td>
          </tr>
        </c:if>
      </table>
    </c:when>
    <c:when test="${empty status and settingsBean.syncEnabled}">
      <h3>Current Status:</h3>
      No settings changes were made since server start
    </c:when>
  </c:choose>
</bs:refreshable>
<script type="text/javascript">
  BS.PeriodicalRefresh.start(${settingsBean.statusUpdateIntervalMillis/1000}, function() {
    $j("#versionedSettingsStatus").get(0).refresh();
  })
</script>

