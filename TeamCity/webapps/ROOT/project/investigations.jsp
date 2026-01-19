<%@ include file="../include-internal.jsp" %><%@
    taglib prefix="tt" tagdir="/WEB-INF/tags/tests" %><%@
    taglib prefix="l" tagdir="/WEB-INF/tags/layout" %><%@
    taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible" %><%@
    page import="jetbrains.buildServer.controllers.investigationsAndMutes.InvestigationsAndMutesConstants" %>

<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request" />
<jsp:useBean id="bean" type="jetbrains.buildServer.controllers.investigate.InvestigationsBean" scope="request" />

<c:url var="url" value='/project.html?projectId=${project.externalId}&tab=investigations'/>
<c:url var="internalUrl" value='/projectRespTab.html?projectId=${project.externalId}'/>
<c:set var="showWithoutTestRunsOptionName" value="${InvestigationsAndMutesConstants.SHOW_WITHOUT_TEST_RUNS_OPTION}"/>
<c:set var="initialPage" value="investigationsOrMutesPage" scope="request"/>

<form action="${internalUrl}" method="post" id="responsibilitiesFilter" class="changeLogFilter">
  <div class="actionBar">
    <span class="nowrap">
      <label class="firstLabel" for="userDropDown">Filter by investigator:</label>
      <forms:select name="selectedUser" id="userDropDown" className="wideUserDropDown actionInput"
                    onchange="BS.Responsibilities.submitFilter();"
                    enableFilter="true">
        <forms:option value="" selected="${not bean.hasSelectedUser}">&lt;All users&gt;</forms:option>
        <forms:option value="${bean.defaultUser.username}" selected="${bean.selectedUser == bean.defaultUser.username}">
          me (${bean.defaultUserResponsibilities})
        </forms:option>
        <c:forEach items="${bean.sortedUsers}" var="pair">
          <forms:option value="${pair.first.username}" selected="${bean.selectedUser == pair.first.username}">
            <bs:fullUsername user="${pair.first}"/> (${pair.second})
          </forms:option>
        </c:forEach>
      </forms:select>
    </span>

    <span class="nowrap">
      <profile:booleanPropertyCheckbox propertyKey="investigations.hideFixed" progress="respRefreshProgress"
                                       labelText="Hide problems marked as fixed" afterComplete="BS.Responsibilities.submitFilter();"/>
    </span>

    <span class="nowrap">
      <profile:booleanPropertyCheckbox propertyKey="investigations.showOnlyForDefaultBranch" progress="respRefreshProgress"
                                       labelText="Show problems only for default branch" afterComplete="BS.Responsibilities.submitFilter();"/>
    </span>

  </div>
  <%@ include file="../investigationsList.jspf" %>
</form>
