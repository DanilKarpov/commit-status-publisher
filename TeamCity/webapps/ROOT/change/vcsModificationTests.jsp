<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="tt" tagdir="/WEB-INF/tags/tests" %>

<jsp:useBean id="modification" type="jetbrains.buildServer.vcs.SVcsModification" scope="request"/>
<jsp:useBean id="failedTestsBean" type="jetbrains.buildServer.controllers.changes.FailedTestsBean" scope="request"/>
<jsp:useBean id="changeDetailsBean" type="jetbrains.buildServer.controllers.changes.ChangeDetails" scope="request"/>

<c:set var="refreshUrl"><bs:vcsModificationUrl change="${modification}"
                                               extension="${extensionTab}"/></c:set>
<bs:refreshable containerId="failedTestsSection" pageUrl="${refreshUrl}">

  <c:set var="buildProblemsBean" value="${changeDetailsBean.buildProblemBean}"/>
  <c:if test="${not empty buildProblemsBean}">
    <c:set var="sectionTitle"><bs:buildProblemIconBase/>Build problems: ${buildProblemsBean.buildProblemsNumber}</c:set>

    <bs:_collapsibleBlock title="${sectionTitle}" id="changeDetailsBuildProblems" collapsedByDefault="false">
      <problems:buildProblemExpandCollapse showExpandCollapseActions="true">
        <jsp:body>
          <problems:buildProblemGroupByProject projectBuildProblemsBean="${buildProblemsBean}" compactMode="false"/>
        </jsp:body>
      </problems:buildProblemExpandCollapse>
    </bs:_collapsibleBlock>
  </c:if>

  <c:choose>
    <c:when test="${not failedTestsBean.hasFailedTests}">
      <div class="newTestsInfo">
       No failed tests
      </div>
    </c:when>
    <c:otherwise>
      <c:if test="${failedTestsBean.hasNewFailedTests}">
        <c:set var="testsNum" value="${failedTestsBean.newTestsNumber}"/>
        <c:set var="btNum" value="${failedTestsBean.newAffectedBuildTypesNumber}"/>

        <c:set var="newTestsTitle">
          <bs:buildProblemIconBase/>${testsNum} new failed test<bs:s val="${testsNum}"/> in ${btNum} build configuration<bs:s val="${btNum}"/>
        </c:set>

        <bs:_collapsibleBlock title="${newTestsTitle}" id="buildNewFailedTests">
          <tt:_testGroupForChange testList="${failedTestsBean.newFailedTests}" defaultOption="bt" id="change_fail"/>
        </bs:_collapsibleBlock>

      </c:if>

      <c:if test="${failedTestsBean.otherTestsNumber > 0}">
        <c:set var="testsNum" value="${failedTestsBean.otherTestsNumber}"/>
        <c:set var="btNum" value="${failedTestsBean.otherAffectedBuildTypesNumber}"/>
        <c:set var="blockHeader">
          ${testsNum} test<bs:s val="${testsNum}"/> failing from previous builds
          in ${btNum} build configuration<bs:s val="${btNum}"/>
        </c:set>        

        <bs:_collapsibleBlock title="${blockHeader}" id="oldTests">
          <tt:_testGroupForChange testList="${failedTestsBean.otherTests}" defaultOption="bt" id="change_other"/>
        </bs:_collapsibleBlock>
      </c:if>
    </c:otherwise>
  </c:choose>
</bs:refreshable>
