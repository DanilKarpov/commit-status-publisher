<%@ page import="jetbrains.buildServer.controllers.admin.healthStatus.HealthStatusTab" %>
<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="results" type="java.util.List" scope="request"/>
<c:set var="error" value="<%=ItemSeverity.ERROR%>"/>
<bs:refreshable containerId="globalHealthItems" pageUrl="${pageUrl}">
  <script>
    BS.globalHealthItems = [];
  </script>
  <div data-health-report-react-container></div>
  <c:forEach items="${results}" var="res">

    <div class="health-report-react-portal" data-health-report-popup-portal="${res.identity}"></div>
    <div data-health-report-identity="${res.identity}" class="${res.severity.error ? 'attentionRed' : 'attentionComment'} hidden clearfix">

      <c:set var="extensionType" scope="request" value="${res.extension.type}"/>
      <c:set var="healthStatusItem" scope="request" value="${res}"/>
      <c:set var="showMode" scope="request" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
      <c:set var="healthStatusReportUrl" scope="request" value="<%=HealthStatusTab.URL%>"/>
      <c:set var="inlineMarkdownMessage" scope="request" value="${false}"/>
      <div class="global-health-item__content"><jsp:include page="/showHealthStatusItem.html"/></div>

      <script>
        (() => {
          const identity = "${res.identity}";
          const severity = "${res.severity.displayName}";
          const canHidePersonal = ("${not res.severity.error and afn:permissionGrantedGlobally('CHANGE_OWN_PROFILE')}" == "true");
          const canHideGlobal = canHidePersonal && ("${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}" == "true");
          BS.globalHealthItems.push({
            identity,
            category: {
              id: "${res.category.id}",
              name: "${res.category.name}"
            },
            extension: {
              type: "${res.extension.type}"
            },
            severity,
            canHidePersonal,
            canHideGlobal,
          });
        })()
      </script>
    </div>
  </c:forEach>
  <c:if test="${empty param.skipRender}">
    <script>
      {
        const container = document.querySelector('[data-health-report-react-container]');
        const existingGroups = ['Error', 'Warning', 'Info'].filter(severity => BS.globalHealthItems.some(item => item.severity === severity));
        container.style.minHeight = existingGroups.length * 40 + 'px';
        ReactUI.renderHealthItems(container, {items: BS.globalHealthItems});
      }
    </script>
  </c:if>
</bs:refreshable>
<c:if test="${intprop:getBooleanOrTrue('teamcity.ui.reloadGlobalHealthItems.enabled')}">
<script type="text/javascript">
  (function () {
    var delay = ${intprop:getInteger('teamcity.ui.reloadGlobalHealthItems.delay.seconds', 5)};
    var dispersion = ${intprop:getInteger('teamcity.ui.reloadGlobalHealthItems.dispersion.seconds', 2)};
    var currentValue = null;
    var updateIsScheduled = false;
    BS.SubscriptionManager.subscribe('global-health-items', function(newValue) {
      if (currentValue != newValue) {
        if (currentValue != null && !updateIsScheduled) {
          updateIsScheduled = true;
          var timeout = delay * 1000 + Math.floor(Math.random() * dispersion * 1000);
          setTimeout(function () {
            var healthItems = document.getElementById('globalHealthItems');
            if (healthItems != null) {
              healthItems.refresh();
            }
            updateIsScheduled = false;
          }, timeout);
        }
        currentValue = newValue;
      }
    });
  })();
</script>
</c:if>
