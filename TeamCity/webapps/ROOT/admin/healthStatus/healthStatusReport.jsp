<%@ page import="jetbrains.buildServer.controllers.admin.healthStatus.HealthStatusReportBean" %>
<%@ page import="jetbrains.buildServer.serverSide.healthStatus.ItemSeverity" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="healthStatusReportBean" type="jetbrains.buildServer.controllers.admin.healthStatus.HealthStatusReportBean" scope="request"/>
<jsp:useBean id="groupedItems" type="java.util.List" scope="request"/>
<jsp:useBean id="totalVisible" type="java.lang.Integer" scope="request"/>
<jsp:useBean id="totalHidden" type="java.lang.Integer" scope="request"/>
<c:url var="reportUrl" value="/admin/healthStatusReport.html"/>
<c:url var="showParamsUrl" value="/admin/healthStatusReportParams.html"/>
<c:set var="error" value="<%=ItemSeverity.ERROR%>"/>
<c:set var="warn" value="<%=ItemSeverity.WARN%>"/>
<c:set var="allProblems" value="<%=HealthStatusReportBean.ALL_PROBLEMS%>"/>
<c:set var="globalProblems" value="<%=HealthStatusReportBean.GLOBAL_PROBLEMS%>"/>
<c:set var="archivedProjectsProblems" value="<%=HealthStatusReportBean.ARCHIVED_PROJECTS_PROBLEMS%>"/>
<bs:linkCSS>
  /css/admin/buildTypeForm.css
  /css/admin/healthStatusReport.css;
  /css/viewType.css
</bs:linkCSS>
<bs:linkScript>
  /js/bs/blocks.js
  /js/bs/blocksWithHeader.js
  /js/bs/healthStatusReport.js
</bs:linkScript>

<form id="filterForm" action="${reportUrl}" onsubmit="return BS.HealthStatusReport.submitScopeForm();">
  <div class="actionBar">
    <div>
      <label for="project">Show results related to:</label>
      <forms:select name="scopeProjectId" id="scopeProjectId" onchange="" enableFilter="true" style="width: 20em;">
        <forms:option value="${allProblems}" selected="${allProblems == healthStatusReportBean.scopeProjectId}">&lt;All Items&gt;</forms:option>
        <forms:option value="${globalProblems}" selected="${globalProblems == healthStatusReportBean.scopeProjectId}">&lt;Global Configuration Items&gt;</forms:option>
        <c:forEach items="${healthStatusReportBean.projects}" var="projectBean">
          <c:set var="project" value="${projectBean.project}" />
          <forms:option value="${project.externalId}"
                        selected="${project.externalId == healthStatusReportBean.scopeProjectId}"
                        className="user-depth-${projectBean.limitedDepth}"
                        title="${project.fullName}">
            <c:out value="${project.extendedName}"/>
          </forms:option>
        </c:forEach>
        <forms:option value="${archivedProjectsProblems}" selected="${archivedProjectsProblems == healthStatusReportBean.scopeProjectId}">&lt;Archived Projects&gt;</forms:option>
      </forms:select>
      &nbsp;<label for="project">with minimal severity:</label>
      <forms:select name="minSeverity" id="minSeverity" onchange="" enableFilter="true" style="width: 6em;">
        <c:forEach items="${healthStatusReportBean.severityItems}" var="severity">
          <forms:option value="${severity}" selected="${severity == healthStatusReportBean.minSeverity}">
            <c:out value="${severity.displayName}"/>
          </forms:option>
        </c:forEach>
      </forms:select>
      &nbsp;
      <input class="btn btn_mini" type="submit" name="submitFilter" value="Generate Report"/>
      &nbsp;
      <span style="cursor: default">
        <forms:saving id="progressIndicator" style="float: none; top: 0;"/>
        <span style="margin-left: 0.5em" id="progressStep" />
      </span>
    </div>
  </div>
</form>


<script type="text/javascript">
  BS.HealthStatusReport.readParamsFromHash();

  //We have global Health Status items that are shown on every page including Health Report page itself.
  //Such items can contian links to the Health Report page with specific scope, catergory or severity.
  //But this links have 'href' that is equal to window.location except hash, so clicking on them doesn't result in page reload.
  //We have to subscribe to 'hashchange' event to handle such links.
  $j(window).on('hashchange', function() { BS.HealthStatusReport.readParamsFromHash(); });
</script>

<bs:refreshable containerId="reportSummary" pageUrl="${pageUrl}">
  <c:if test="${healthStatusReportBean.lastFinishedHealthAnalysis != null}">
    <c:set var="totalItems" value="${totalVisible + totalHidden}"/>
    <c:choose>
      <c:when test="${totalItems > 0}">
        <div class="grayNote" style="float: right">Created in <bs:printTime time="${healthStatusReportBean.lastFinishedHealthAnalysis.duration / 1000}"/></div>
        <p class="resultsTitle">
          Found <strong>${totalVisible}</strong> item<bs:s val="${totalVisible}"/>
          <c:if test="${totalHidden > 0}">(and <strong>${totalHidden}</strong> hidden)</c:if>
        </p>
      </c:when>
      <c:otherwise>
        <p class="resultsTitle">No items to show</p>
      </c:otherwise>
    </c:choose>
  </c:if>
</bs:refreshable>

<bs:refreshable containerId="reportCategories" pageUrl="${pageUrl}">
  <c:if test="${healthStatusReportBean.lastFinishedHealthAnalysis != null}">

    <c:if test="${not empty groupedItems}">
      <table id="reportsLayout">
        <tr>
          <td class="categories">
            <div class="category-list">
              <c:forEach items="${groupedItems}" var="itemsGroup" varStatus="pos">
                <%--@elvariable id="itemsGroup" type="jetbrains.buildServer.controllers.admin.healthStatus.GroupedItemsBean"--%>
                <c:set var="category" value="${itemsGroup.category}" />
                <div id="${category.id}" class="item" onclick="return BS.HealthStatusReport.selectCategory('<bs:escapeForJs text="${category.id}"/>', event);">
                  <div class="name">
                    <bs:itemSeverity severity="${category.severity}" suggestion="${category.id == 'suggestion'}"/>
                    <a><c:out value="${category.name}"/></a>
                    <c:if test="${not empty category.helpUrl}">
                      <a href="${category.helpUrl}" class="helpIcon actionIconWrapper" target="_blank" rel="noreferrer"><bs:helpIcon/></a>
                    </c:if>
                  </div>
                  <c:if test="${not empty category.description}">
                    <bs:smallNote><c:out value="${category.description}"/></bs:smallNote>
                  </c:if>
                  <div class="found">
                    <c:set var="visibleItemsCount" value="${fn:length(itemsGroup.visibleResults)}"/>
                    <c:set var="hiddenItemsCount" value="${fn:length(itemsGroup.hiddenResults)}"/>
                    <c:choose>
                      <c:when test="${visibleItemsCount == 0}"><span>${hiddenItemsCount}</span> hidden item<bs:s val="${hiddenItemsCount}"/></c:when>
                      <c:when test="${hiddenItemsCount == 0}"><span>${visibleItemsCount}</span> item<bs:s val="${visibleItemsCount}"/></c:when>
                      <c:otherwise><span>${visibleItemsCount}</span> visible and <span>${hiddenItemsCount}</span> hidden items</c:otherwise>
                    </c:choose>
                  </div>
                </div>
              </c:forEach>
            </div>
          </td>
          <td class="selected-category">
            <div id="update_progress"></div>
            <div id="selectedCategoryItems"></div>
          </td>
        </tr>
      </table>

      <script type="text/javascript">
        (function() {
          var existingCategoryIds = [];
          <c:forEach items="${groupedItems}" var="itemsGroup" varStatus="pos">
          existingCategoryIds.push('<bs:escapeForJs text="${itemsGroup.category.id}"/>');
          </c:forEach>
          BS.HealthStatusReport.newCategoriesLoaded(existingCategoryIds);
        })();

        $j('.helpIcon').click(function(event){
          event.stopImmediatePropagation();
        });
      </script>
    </c:if>
  </c:if>
</bs:refreshable>
