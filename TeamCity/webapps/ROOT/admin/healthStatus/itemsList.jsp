<%@ page import="jetbrains.buildServer.controllers.admin.healthStatus.HealthStatusTab" %>
<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<c:choose>
  <c:when test="${selectedItemsGroup == null}">
    No items found.
  </c:when>
  <c:otherwise>
    <jsp:useBean id="selectedItemsGroup" type="jetbrains.buildServer.controllers.admin.healthStatus.GroupedItemsBean" scope="request"/>
    <c:set var="category" value="${selectedItemsGroup.category}" />
    <c:set var="visibleResults" value="${selectedItemsGroup.visibleResults}" />
    <c:set var="hiddenResults" value="${selectedItemsGroup.hiddenResults}" />

    <c:set var="error" value="<%=ItemSeverity.ERROR%>"/>
    <c:set var="warn" value="<%=ItemSeverity.WARN%>"/>

    <c:set var="visibleItemsCount" value="${fn:length(visibleResults)}"/>
    <c:set var="hiddenItemsCount" value="${fn:length(hiddenResults)}"/>

    <c:if test="${not empty visibleResults or not empty hiddenResults}">
      <l:tableWithHighlighting highlightImmediately="true" className="healthItemsTable">
        <c:set var="applyVisibilityGlobally" value="${afn:permissionGrantedGlobally('CHANGE_SERVER_SETTINGS')}"/>
        <c:forEach items="${visibleResults}" var="itemEx">
          <c:set var="item" value="${itemEx.item}" />
          <c:set var="showHide" value="${not itemEx.item.severity.error and afn:permissionGrantedGlobally('CHANGE_OWN_PROFILE')}"/>
          <tr>
            <td class="healthStatusItem">
              <bs:itemSeverity severity="${item.severity}" suggestion="${item.category.id == 'suggestion'}"/>
              <c:set var="healthStatusItem" scope="request" value="${item}"/>
              <c:set var="extensionType" scope="request" value="${item.extension.type}"/>
              <c:set var="showMode" scope="request" value="<%=HealthStatusItemDisplayMode.GLOBAL%>"/>
              <c:set var="healthStatusReportUrl" scope="request" value="<%=HealthStatusTab.URL%>"/>
              <c:set var="inlineMarkdownMessage" scope="request" value="${true}"/>
              <jsp:include page="/showHealthStatusItem.html"/>
            </td>
            <td class="healthStatusHide">
              <bs:hideHealthItem item="${item}" refreshFunc="BS.HealthStatusReport.refreshContent()" lastAuditAction="${itemEx.lastAuditAction}"/>
            </td>
          </tr>
        </c:forEach>

        <c:if test="${not empty hiddenResults}">
          <tr class="beforeHiddenItems">
            <td style="${not empty visibleResults ? 'padding-top: 2em;' : ''}"><strong>${hiddenItemsCount}</strong> hidden item<bs:s val="${hiddenItemsCount}"/>.</td>
            <td></td>
          </tr>
        </c:if>

        <c:forEach items="${hiddenResults}" var="itemEx" varStatus="pos">
          <c:set var="item" value="${itemEx.item}" />
          <c:set var="hiddenForCurrentUser" value="${itemEx.item.visibleGlobally}" />
          <tr class="hiddenItem">
            <td class="healthStatusItem">
              <bs:itemSeverity severity="${item.severity}" suggestion="${item.category.id == 'suggestion'}"/>
              <c:set var="healthStatusItem" scope="request" value="${item}"/>
              <c:set var="extensionType" scope="request" value="${item.extension.type}"/>
              <c:set var="showMode" scope="request" value="<%=HealthStatusItemDisplayMode.GLOBAL%>"/>
              <c:set var="healthStatusReportUrl" scope="request" value="<%=HealthStatusTab.URL%>"/>
              <c:set var="inlineMarkdownMessage" scope="request" value="${true}"/>
              <jsp:include page="/showHealthStatusItem.html"/>
            </td>
            <td class="healthStatusHide">
              <c:if test="${hiddenForCurrentUser or applyVisibilityGlobally}">
                <c:set var="lastAuditAction" value="${itemEx.lastAuditAction}"/>
                <c:if test="${not hiddenForCurrentUser and lastAuditAction != null}">
                  <bs:commentIcon flip="true">
                    <jsp:attribute name="text">
                      Was hidden <bs:date value="${lastAuditAction.timestamp}" smart="true" no_smart_title="true"/> by <strong><admin:auditLogActionUserName auditLogAction="${lastAuditAction}"/></strong>
                    </jsp:attribute>
                  </bs:commentIcon>
                </c:if>
                <a href="#" title="Restore health report item visibility"
                   onclick="return BS.HealthStatusReport.setHealthItemVisibility('<bs:escapeForJs text="${extensionType}"/>', '<bs:escapeForJs text="${item.category.id}"/>', '<bs:escapeForJs text="${item.identity}"/>', true, ${not hiddenForCurrentUser and applyVisibilityGlobally})">Show</a>
              </c:if>
            </td>
          </tr>
        </c:forEach>
      </l:tableWithHighlighting>
    </c:if>
  </c:otherwise>
</c:choose>

