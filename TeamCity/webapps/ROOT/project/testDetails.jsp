<%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
<%--@elvariable id="error" type="java.lang.String"--%>

<%@ page import="java.util.Map" %><%@
    page import="jetbrains.buildServer.web.openapi.PlaceId" %><%@
    page import="jetbrains.buildServer.web.util.WebUtil" %><%@
    include file="/include-internal.jsp"%><%@
    taglib prefix="stats" tagdir="/WEB-INF/tags/graph" %><%@
    taglib prefix="props" tagdir="/WEB-INF/tags/props" %><%@
    taglib prefix="tt" tagdir="/WEB-INF/tags/tests"

%><c:if test="${not empty error}">${error}</c:if
><c:if test="${empty error}">
<div class="testDetails">

<jsp:useBean id="historyPager" type="jetbrains.buildServer.util.Pager" scope="request"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request" />
<jsp:useBean id="buildTypes" type="java.util.Collection<jetbrains.buildServer.web.util.BuildTypesHierarchyBean>" scope="request" />
<jsp:useBean id="test" type="jetbrains.buildServer.serverSide.STest" scope="request"/>
<jsp:useBean id="summary" type="jetbrains.buildServer.controllers.buildType.TestSummaryBean" scope="request"/>
<jsp:useBean id="order" type="jetbrains.buildServer.controllers.TestHistoryOrder" scope="request"/>
<jsp:useBean id="historyRecords" type="java.util.Collection<jetbrains.buildServer.serverSide.STestRun>" scope="request"/>

<c:set var="packageString" value="${empty test.name.packageName ? 'no package' : test.name.packageName}"/>
<c:set var="allResp" value="${test.allResponsibilities}"/>
<c:set var="resp" value="${not empty allResp ? allResp[0] : null}"/>

<script type="text/javascript">
  BS.Util.setTitle("<bs:escapeForJs text="${project.name} > Test History of ${test.name.shortName}"/>");
</script>

<h2 class="testNameHeader">
  <span style="padding-right: 4px;">Test:</span>
  <tt:testNameWithPopupShort test="${test}" trimTestName="${true}" showPackage="${true}" flakyIconVisible="${true}" showTestHistoryLink="false"/>
  <span id="test_name_${test.testNameId}" style="display: none"><c:out value="${test.name.nameWithoutParameters}"/></span>
  <bs:copy2ClipboardLink dataId="test_name_${test.testNameId}"></bs:copy2ClipboardLink>
</h2>

<div class="buildTypeSelector actionBar">
  <form action="#" name="fake">
    <span class="nowrap">
      <label class="firstLabel" for="buildTypeId">Filter by project or build configuration:</label>

      <c:set var="selectedBuildTypeId" value="${empty buildType ? '' : buildType.externalId}"/>
      <select hidden name="buildType" id="buildType"><c:forEach items="${buildTypes}" var="bean"
      ><option value="${bean.project.externalId}"
                     data-project-id="${bean.project.externalId}"
                     <c:if test="${not selectedBuildTypeId and bean.project.projectId == project.projectId}">selected="selected"</c:if>
        ></option
        ><c:forEach var="buildType" items="${bean.buildTypes}"
        ><option value="projectId=${buildType.project.externalId}&buildTypeId=${buildType.externalId}"
                       data-build-type-id="${buildType.externalId}"
                       <c:if test="${buildType.externalId == selectedBuildTypeId}">selected="selected"</c:if>
        ></option
        ></c:forEach
        ></c:forEach
      ></select>
      <div style="display: inline-block; max-width: calc(100% - 260px);" id="buildTypeSelect"></div>
      <c:url var="url" value="/project.html?tab=testDetails&testNameId=${test.testNameId}"/>
      <script>
        {
          const select = document.getElementById('buildType');
          const options = [...select.options];
          const projectIds = options.map(option => option.dataset.projectId);
          const buildTypeIds = options.map(option => option.dataset.buildTypeId);
          const selectedProjectId = projectIds[select.selectedIndex];
          const selectedBuildTypeId = buildTypeIds[select.selectedIndex];
          ReactUI.renderConnected(document.getElementById('buildTypeSelect'), ReactUI.ProjectBuildTypeSelect, {
            expandAll: true,
            projectsSelectable: true,
            includedProjects: projectIds,
            includedBuildTypes: buildTypeIds,
            selected: selectedProjectId != null
                      ? {nodeType: 'project', id: selectedProjectId}
                      : selectedBuildTypeId != null ? {nodeType: 'bt', id: selectedBuildTypeId} : null,
            onSelect(item) {
              var order = location.search.toQueryParams()['order'];
              var url;
              switch (item.nodeType) {
                case 'project':
                  select.selectedIndex = projectIds.indexOf(item.id);
                  url = '${url}' + '&projectId=' + item.id;
                  break;
                case 'bt':
                  select.selectedIndex = buildTypeIds.indexOf(item.id);
                  url = '${url}' + '&' + select.value;
              }
              if (order) {
                url += '&order=' + order;
              }
              document.location.href = url;
              return false;
            }
          })
        }
      </script>
    </span>
  </form>
</div>

<c:set var="duration">
  <i class="tc-icon_before icon16 tc-icon_graph"></i>
  <c:set var="failureStyle" value=""/>
  <c:if test="${summary.failures > 0}"><c:set var="failureStyle" value="color:#a90f1a"/></c:if>
  <span class="testSuccessRateStats">Success rate: <strong><c:choose><c:when test="${summary.successRate < 0}">--</c:when><c:otherwise><fmt:formatNumber value="${summary.successRate * 100}" minFractionDigits="1" maxFractionDigits="1"/>%</c:otherwise></c:choose></strong></span>
  <span class="testRunsStats">Test runs: <strong>${summary.totalRuns}</strong> total / <strong style="${failureStyle}">${summary.failures}</strong> failures / <strong>${summary.timesIgnored}</strong> ignored</span>
</c:set>
<c:set var="statsId" value="testStats"/>
<l:blockStateCss blocksType="Block_${statsId}" collapsedByDefault="false" id="${statsId}Dl"/>
<div class="testDetailsHeader tc-icon_before icon16 blockHeader expanded" id="${statsId}">${duration}</div>
<div class="testDurationContents" id="${statsId}Dl">
  <c:set var="graphUrl" value="/tests/testDurGraph.jsp"/>
  <c:import url="${graphUrl}">
    <c:param name="jsp">${graphUrl}</c:param>
  </c:import>
</div>

<ext:includeExtensions placeId = "<%= PlaceId.TEST_HISTORY %>"/>

<c:if test="${not empty resp and (resp.state.active or resp.state.fixed)}">
  <c:if test="${resp.state.active}">
    <c:set var="investigationNote">Investigator:
      <c:if test="${resp.responsibleUser == currentUser}">you</c:if>
      <c:if test="${resp.responsibleUser != currentUser}"><c:out value="${resp.responsibleUser.descriptiveName}"/></c:if>
    </c:set>
  </c:if>
  <c:if test="${resp.state.fixed}">
    <c:set var="investigationNote">Fixed by
      <c:out value="${resp.responsibleUser == currentUser ? 'you' : resp.responsibleUser.descriptiveName}"/>
    </c:set>
  </c:if>
  <c:set var="investigationNote"><span class="investigation"><bs:responsibleIcon responsibility="${resp}"/>${investigationNote}</span></c:set
></c:if
><c:if test="${test.muted}">
  <c:set var="muteNote">
    <c:set var="currentMuteInfo" value="${test.currentMuteInfo}"/>
    <c:set var="projectsMuteInfo" value="${currentMuteInfo.projectsMuteInfo}"/>
    <c:set var="inScope"
      ><c:choose>
        <c:when test="${not empty projectsMuteInfo}">
          <c:set var="num" value="${fn:length(projectsMuteInfo)}"
          />in <c:out value="${num}"/> project<bs:s val="${num}"/>
        </c:when>
        <c:otherwise>
          <c:set var="num" value="${fn:length(currentMuteInfo.buildTypeMuteInfo)}"
          />in <c:out value="${num}"/> build configuration<bs:s val="${num}"/>
        </c:otherwise>
      </c:choose
      ></c:set
    ><span class="mute"><bs:buildProblemIconBase type="muted"/>Muted ${inScope}</span>
  </c:set>
</c:if>

<c:if test="${not empty investigationNote or not empty muteNote}">
  <c:set var="investId" value="testInvest"/>
  <l:blockStateCss blocksType="Block_${investId}" collapsedByDefault="false" id="${investId}Dl"/>
  <div class="testDetailsHeader tc-icon_before icon16 blockHeader expanded" id="${investId}">${investigationNote}${muteNote}</div>
  <div id="${investId}Dl">
    <table id="investigation-section">
      <tr>
        <c:if test="${not empty investigationNote}">
          <td class="half">
            <bs:responsibleTooltip responsibilities="${allResp}" test="${test}" noActions="true"/>
          </td>
        </c:if>
        <c:if test="${not empty muteNote}">
          <td class="half">
            <bs:muteInfoTooltip test="${test}"/>
          </td>
        </c:if>
        <c:if test="${empty muteNote or empty investigationNote}">
          <td class="half">&nbsp;</td>
        </c:if>
      </tr>
    </table>
    <authz:authorize projectId="${test.projectId}" anyPermission="ASSIGN_INVESTIGATION,MANAGE_BUILD_PROBLEMS">
      <div class="actions">
        <tt:testInvestigationLinks test="${test}" buildId="" withFix="${not empty resp && resp.state.active}"/>
      </div>
    </authz:authorize>
  </div>
</c:if>

<c:url var="actionUrl" value="project.html"/>

<div class="testHistoryHeader">
  <form id="testFilter" action="${actionUrl}" method="GET">

    <input type="hidden" name="projectId" value="${project.externalId}"/>
    <c:set var="bt"><c:if test="${not empty buildType}">${buildType.buildTypeId}</c:if></c:set>
    <input type="hidden" name="buildTypeId" value="${bt}"/>
    <input type="hidden" name="tab" value="testDetails"/>
    <input type="hidden" name="testNameId" value="${test.testNameId}"/>
    <input type="hidden" name="order" value="<%=order.name()%>">

    <%--@elvariable id="branchBean" type="jetbrains.buildServer.controllers.BranchBean"--%>
    <c:if test="${not empty branchBean}">
      <input type="hidden" name="branch_${project.externalId}" value="${branchBean.userBranch}"/>
    </c:if>

    <div class="testCountBlock">
      <label for="itemsCount">Builds to show:</label>
      <select name="itemsCount" id="itemsCount" onchange="$('testFilter').submit(); return true;">
        <c:set var="selectedValue" scope="request" value="${itemsCount}"/>

        <props:option value="50">50</props:option>
        <props:option value="100">100</props:option>
        <props:option value="500">500</props:option>
        <props:option value="-1">All</props:option>
      </select>
    </div>
    <h2>Test History</h2>
  </form>
</div>

<tt:testHistoryTable historyRecords="${historyRecords}" updateFormId="testFilter" showBuildTypes="${empty buildType}"/>

<c:set var="pagerUrlPattern">
  project.html?<c:forEach items="${param}" var="entry"
    ><c:if test="${entry.key != 'page'}">${entry.key}=<%=WebUtil.encode((String)((Map.Entry)pageContext.getAttribute("entry")).getValue())%>&</c:if
    ></c:forEach>page=[page]
</c:set>

<bs:pager place="bottom" urlPattern="${pagerUrlPattern}" pager="${historyPager}"/>

</div>

<script type="text/javascript">
  (function() {
    <l:blockState blocksType="Block_${statsId}"/>
    new (Class.create(BS.BlocksWithHeader, {
      onShowBlock: function($super, contentElement, id) {
        $super(contentElement, id);
        if (BS.Chart) {
          $j(window).trigger('resize');
        }
      }
    }))('${statsId}');

    <c:if test="${not empty investId}">
      <l:blockState blocksType="Block_${investId}"/>
      new BS.BlocksWithHeader('${investId}');
    </c:if>

    BS.Branch.injectBranchParamToLinks($j("a.buildTypeName").parent(), "${project.externalId}");
    BS.Branch.baseUrl = "<c:url value="/project.html?projectId=${project.externalId}&tab=testDetails&testNameId=${test.testNameId}"/>";

    BS.TestMetadata.installHandlerForTestLists('.testList');
  })();
</script>
</c:if>
