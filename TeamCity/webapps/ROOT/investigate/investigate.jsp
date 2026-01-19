<%@ include file="../include-internal.jsp" %><%@
    taglib prefix="tt" tagdir="/WEB-INF/tags/tests" %><%@
    taglib prefix="l" tagdir="/WEB-INF/tags/layout" %><%@
    taglib prefix="problems" tagdir="/WEB-INF/tags/problems" %><%@
    taglib prefix="resp" tagdir="/WEB-INF/tags/responsible"
%><%@ page import="jetbrains.buildServer.controllers.investigationsAndMutes.InvestigationsAndMutesConstants" %>
<bs:page>
  <jsp:attribute name="page_title">My Investigations</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/filePopup.css
      /css/changeLog.css
      /css/viewModification.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/blocks.js
      /js/bs/blockWithHandle.js

      /js/bs/testGroup.js

      /js/bs/systemProblemsMonitor.js
      /js/bs/collapseExpand.js
      /js/bs/visibleDialog.js
      /js/bs/overflower.js

      /js/bs/blocksWithHeader.js
      /js/bs/buildResultsDiv.js
      /js/bs/async.js
      /js/bs/testDetails.js
    </bs:linkScript>
    <script type="text/javascript">
      BS.Navigation.items = [
          {title: "My Investigations", selected:true}
      ];
    </script>
  </jsp:attribute>

  <jsp:attribute name="quickLinks_include">
    <bs:openInSakuraUI investigations="${true}" />
  </jsp:attribute>

  <jsp:attribute name="body_include">
    <c:url var="url" value='/investigations.html?'/>
    <c:set var="showWithoutTestRunsOptionName" value="${InvestigationsAndMutesConstants.SHOW_WITHOUT_TEST_RUNS_OPTION}"/>
    <c:set var="initialPage" value="investigationsOrMutesPage" scope="request"/>
    <c:set var="doNotHighlightMyInvestigation" value="true" scope="request"/>

    <div class="actionBar">
      <span class="nowrap">
        <profile:booleanPropertyCheckbox propertyKey="investigations.hideFixed" progress="hideFixed_progress"
                                         labelText="Hide problems marked as fixed"
                                         afterComplete="if($('responsibilitiesTable')) $('responsibilitiesTable').refresh('hideFixed_progress');"/>
      </span>
      <span class="nowrap">
        <profile:booleanPropertyCheckbox propertyKey="investigations.showOnlyForDefaultBranch" progress="hideFixed_progress"
                                         labelText="Show problems only for default branch"
                                         afterComplete="if($('responsibilitiesTable')) $('responsibilitiesTable').refresh('hideFixed_progress');"/>
      </span>

      <forms:saving id="hideFixed_progress" className="progressRingInline" savingTitle="Refreshing list of investigations"/>
    </div>

    <%@ include file="../investigationsList.jspf" %>
  </jsp:attribute>
</bs:page>
