<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="tt" tagdir="/WEB-INF/tags/tests"%>

<jsp:useBean id="changeStatus" type="jetbrains.buildServer.vcs.ChangeStatus" scope="request"/>
<jsp:useBean id="changeDetailsBean" type="jetbrains.buildServer.controllers.changes.ChangeDetails" scope="request"/>
<jsp:useBean id="regularBuildTypesStatus" type="java.util.Map" scope="request"/>
<jsp:useBean id="numRegularBuilds" type="java.lang.Integer" scope="request"/>

<c:set var="key"><bs:_csId changeStatus="${changeStatus}"/></c:set>

<c:if test="${changeDetailsBean.problemsSectionNeeded}">
  <c:set var="problemText"><%@ include file="_changeProblemSummary.jspf" %></c:set>
</c:if>

<div class="expandedDetails">
<div class="expandedChange" id="expanded_view_${key}">

  <!-- Tabs: -->
  <div id="changeTabs_${key}" class="simpleTabs clearfix"></div>

  <%-- change problems --%>
  <c:if test="${changeDetailsBean.problemsSectionNeeded}">
    <div class="sectionContent" id="problems_${key}" style="display: none;">

      <c:set var="buildProblemsBean" value="${changeDetailsBean.buildProblemBean}"/>
      <c:if test="${not empty buildProblemsBean}">
        <div class="sectionTitle">${buildsText}</div>

        <problems:buildProblemExpandCollapse showExpandCollapseActions="false">
          <jsp:body>
            <problems:buildProblemGroupByProject projectBuildProblemsBean="${buildProblemsBean}" compactMode="false"/>
          </jsp:body>
        </problems:buildProblemExpandCollapse>
      </c:if>

      <div class="sectionTitle">${testsText}</div>
      <%@ include file="_changeProblemTestSection.jspf" %>

      <div class="moreBlock">
        <bs:modificationLink modification="${changeStatus.change}" tab="vcsModificationTests">
          View all problems & tests on the change page &raquo;
        </bs:modificationLink>
      </div>
    </div>
  </c:if>

  <%-- change builds --%>
<c:if test="${numRegularBuilds gt 0}">
  <div class="sectionContent" id="builds_${key}" style="display: none;">
    <c:set var="modification" value="${changeStatus.change}" scope="request"/>
    <c:set var="refreshJS" value="BS.changeTree.refreshChangeDetails('ct_node_${key}');" scope="request"/>
    <%@include file="/change/vcsModificationBuilds.jsp"%>

    <div class="moreBlock">
      <bs:modificationLink modification="${modification}" tab="vcsModificationBuilds&show_all_builds=true">
        View all builds on the change page &raquo;
      </bs:modificationLink>
    </div>
  </div>
  </c:if>

  <%-- change files --%>
  <c:if test="${changeDetailsBean.changedFilesCount > 0}">
    <div class="sectionContent" id="files_${key}" style="display: none;">
      <bs:changedFiles changes="${modificationFilesBean.changesToShow}"
                       modification="${modificationFilesBean.modification}"
                       openLinkInSameTab="${modificationFilesBean.openFileLinksInSameTab}"
                       highlightChange="${modificationFilesBean.highlightChange}"
          />
      <div class="moreBlock">
        <bs:modificationLink modification="${modification}" tab="vcsModificationFiles">
          View change details &raquo;
        </bs:modificationLink>
      </div>
    </div>
  </c:if>

</div>
</div>
<c:if test="${not param['update']}">
<script>
  (function() {
    var switch_tab = function(tab) {
      $j("#expanded_view_${key}").find("div.sectionContent").each(function() {
        this.style.display = this.id == tab.getId() ? 'block' : 'none'; // Need this for synchronous DOM update to fix TW-58903
      });
    };

    var tabs = new TabbedPane();
    <c:if test="${changeDetailsBean.problemsSectionNeeded}">
      tabs.addTab('problems_${key}', { caption: 'Problems & <span class="first-letter">T</span>ests', onselect: switch_tab });
    </c:if>

    <c:if test="${numRegularBuilds gt 0}">
    tabs.addTab('builds_${key}', { caption: '<span class="first-letter">B</span>uilds (${numRegularBuilds})', onselect: switch_tab });
    </c:if>

    <c:if test="${changeDetailsBean.changedFilesCount > 0}">
      tabs.addTab('files_${key}', { caption: '<span class="first-letter">F</span>iles (${changeDetailsBean.changedFilesCount})', onselect: switch_tab });
    </c:if>

    var node = BS.changeTree.getNode('ct_node_${key}');
    node.setTabs(tabs);
  })();
</script>
</c:if>
