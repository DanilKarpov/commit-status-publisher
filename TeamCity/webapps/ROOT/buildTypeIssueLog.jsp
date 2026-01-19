<%@ include file="include-internal.jsp" %>
<jsp:useBean id="buildType" type="jetbrains.buildServer.serverSide.SBuildType" scope="request"/>
<jsp:useBean id="bean" type="jetbrains.buildServer.controllers.buildType.tabs.IssueLogBean" scope="request"/>
<%@ include file="_subscribeToCommonBuildTypeEvents.jspf"
%><c:choose>
<c:when test="${bean.numberOfIssues > 0 || bean.hideRelated || not empty bean.from || not empty bean.to}">
<%--@elvariable id="branchBean" type="jetbrains.buildServer.controllers.BranchBean"--%>
<c:set var="branchParam" value=""/>
<c:if test="${not empty branchBean}">
  <c:set var="branchParam" value="branch_${buildType.projectExternalId}=${util:urlEscape(branchBean.userBranch)}"/>
</c:if>
<c:set var="btId" value="${buildType.buildTypeId}"/>
<c:set var="baseUrl" value="/viewType.html?buildTypeId=${buildType.externalId}&tab=buildTypeIssueLog"/>
<c:if test="${not empty branchParam}"><c:set var="baseUrl" value="${baseUrl}&${branchParam}"/></c:if>
<c:url var="pagerUrlPattern" value="${baseUrl}&page=[page]"/>
<c:url var="url" value="${baseUrl}"/>

<div id="buildTypeIssueLog" class="logTable">
<form action="${url}" method="post" id="issueLogFilter" class="issueLogFilter" onsubmit="return BS.IssueLog.submitFilter();">
  <bs:refreshable containerId="issueLogTable" pageUrl="${url}">
    <div class="actionBar">
      <span class="actionBarRight">
        <bs:resultsPerPage pager="${bean.pager}" onchange="BS.IssueLog.submitFilter();"/>
      </span>

      <span class="nowrap">
        <label for="from" class="firstLabel changeFilter">Show issues from: </label>
        <forms:textField id="from" className="actionInput short" name="from" value="${bean.from}" defaultText="<build #>"/>
      </span>
      <span class="nowrap">
        <label for="to">to: </label>
        <forms:textField id="to" className="actionInput short" name="to" value="${bean.to}" defaultText="<build #>"/>
      </span>
      <forms:filterButton/>
      <c:if test="${not empty bean.from or not empty bean.to}"><forms:resetFilter resetHandler="BS.IssueLog.submitFilter(true);"/></c:if>
      <forms:saving className="progressRingInline"/>
    </div>

    <p class="resultsTitle">
      <c:url var="permalink" value='${baseUrl}'/>
      <c:set var="permalink" value='${permalink}&from=${util:urlEscape(bean.from)}&to=${util:urlEscape(bean.to)}'/>
      <c:set var="permalink" value='${permalink}&showBuilds=${bean.showBuilds}'/>
      <c:set var="permalink" value='${permalink}&hideRelated=${bean.hideRelated}'/>
      <span class="changeLogPermalink">
        <a href="${permalink}">Permalink</a>
      </span>

      <c:if test="${bean.pager.totalRecords > 0}">
        <c:url var="csvLink" value="/get/issues/${buildType.externalId}/${buildType.externalId}-issues.csv"/>
        <c:if test="${not empty branchParam}"><c:set var="csvLink" value="${csvLink}?${branchParam}"/></c:if>
        <c:set var="issues">
          ${bean.numberOfIssues > 1 ? 'all' : ''} issue<bs:s val="${bean.numberOfIssues}"/>
        </c:set>
        <a class="downloadLink tc-icon_before icon16 tc-icon_download" href="${csvLink}" style="margin-right: 1.5em;" title="Download filtered issues in CSV format">Download ${issues} in CSV</a>
      </c:if>

      <span class="changeLogToggle">
        <forms:checkbox id="showBuilds" name="showBuilds" checked="${bean.showBuilds}"
                        onclick="BS.IssueLog.submitFilter();"/>
        <label for="showBuilds">Show builds</label>
      </span>
      <span class="changeLogToggle">
        <forms:checkbox id="hideRelated" name="hideRelated" checked="${bean.hideRelated}"
                        onclick="BS.IssueLog.submitFilter();"/>
        <label for="hideRelated">Show only resolved issues</label>
      </span>
    </p>

    <c:set var="visibleRows" value="${bean.visibleRows}"/>

    <c:if test="${bean.fetchingIssues}">
      <div class="attentionComment">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Some of the issues are being retrieved from the issue-tracker system.
        Refresh the page to see the updates.
      </div>
    </c:if>
    <c:if test="${fn:length(visibleRows) > 0}">
      <table class="issueLogTable separatedWithLine overviewTypeTable">
        <c:forEach items="${visibleRows}" var="row" varStatus="pos">
          <c:choose>
            <c:when test="${row.build != null}">
              <tr>
                <td colspan="4">
                  <div class="captionRow">
                    <bs:changeLogBuildRow build="${row.build}"
                                          showBuildTypeInBuilds="${false}"
                                          showBranch="${bean.showBranch}"/>
                  </div>
                </td>
              </tr>
            </c:when>
            <c:when test="${row.type == 'MERGED_ISSUES_ROW'}">
              <%--@elvariable id="row" type="jetbrains.buildServer.controllers.buildType.tabs.IssueLogBean.MergedIssuesRow"--%>
              <bs:_issueLogRow issue="${row.issue}">
                <jsp:attribute name="details">
                  <td>
                    <c:set var="mods" value="${row.relatedModifications}"/>
                    <c:set var="rows" value="${row.modificationsDetails}"/>
                    <c:set var="builds" value="${row.relatedBuilds}"/>
                    <c:set var="body" value=""/>
                    <c:if test="${not empty mods}">
                      <c:set var="body">${fn:length(mods)} modification<bs:s val="${fn:length(mods)}"/></c:set>
                      <c:if test="${not empty rows}">
                        <c:set var="body">${body} (merged from ${fn:length(rows)} row<bs:s val="${fn:length(rows)}"/>)</c:set>
                      </c:if>
                    </c:if>
                    <c:if test="${not empty mods and not empty builds}">
                      <c:set var="body" value="${body} and "/>
                    </c:if>
                    <c:if test="${not empty builds}">
                      <c:set var="body">${body}${fn:length(builds)} build comment<bs:s val="${fn:length(builds)}"/></c:set>
                    </c:if>
                    <bs:popup_static controlId="merged_${util:uniqueId()}">
                      <jsp:attribute name="content">
                        <c:forEach items="${rows}" var="modRow">
                          <div>
                            <c:set var="change" value="${modRow.first}"/>
                            <c:set var="build" value="${modRow.second}"/>
                            <bs:changedFilesLink modification="${change}"
                                                 build="${build}"><bs:changeCommitters modification="${change}"/></bs:changedFilesLink>
                            <c:choose>
                              <c:when test="${build.buildId > 0}">
                                in <bs:buildLink build="${build}">build #${build.buildNumber}</bs:buildLink>
                              </c:when>
                              <c:otherwise><i>(pending)</i></c:otherwise>
                            </c:choose>
                          </div>
                        </c:forEach>
                        <c:forEach items="${builds}" var="build">
                          <div>
                            Build comment in <bs:buildLink build="${build}">build #${build.buildNumber}</bs:buildLink>
                          </div>
                        </c:forEach>
                      </jsp:attribute>
                      <jsp:body>${body}</jsp:body>
                    </bs:popup_static>
                  </td>
                </jsp:attribute>
              </bs:_issueLogRow>
            </c:when>
            <c:otherwise>
              <%--@elvariable id="row" type="jetbrains.buildServer.controllers.buildType.tabs.IssueLogRow"--%>
              <bs:_issueLogRow issue="${row.issue}">
                <jsp:attribute name="details">
                  <c:set var="change" value="${row.issue.relatedModification}"/>
                  <c:choose>
                    <c:when test="${change != null}">
                      <td class="changedFiles">
                        <c:set var="build" value="${change.firstBuilds[buildType]}"/>
                        <c:choose>
                          <c:when test="${not empty build}">
                            <bs:changedFilesLink modification="${change}"
                                                 build="${build}"><bs:changeCommitters modification="${change}"/></bs:changedFilesLink>
                          </c:when>
                          <c:otherwise>
                            <bs:changedFilesLink modification="${change}"
                                                 buildType="${buildType}"><bs:changeCommitters modification="${change}"/></bs:changedFilesLink>
                          </c:otherwise>
                        </c:choose>
                      </td>
                    </c:when>
                    <c:otherwise>
                      <td>
                        <c:set value="${row.relatedBuild}" var="build"/>
                        <bs:buildLink build="${build}">Build comment</bs:buildLink>
                      </td>
                    </c:otherwise>
                  </c:choose>
                </jsp:attribute>
              </bs:_issueLogRow>
            </c:otherwise>
          </c:choose>
        </c:forEach>
      </table>

      <c:if test="${bean.pager.totalRecords > 0}">
        <bs:pager place="bottom" urlPattern="${pagerUrlPattern}" pager="${bean.pager}"/>
      </c:if>
    </c:if>
    <c:if test="${bean.pager.totalRecords > 0}">
      <c:set var="pagerDesc">
        ${bean.numberOfIssues} issue<bs:s val="${bean.numberOfIssues}"/>
      </c:set>

      <bs:pager place="title" urlPattern="${pagerUrlPattern}" pager="${bean.pager}" pagerDesc="${pagerDesc}"/>
    </c:if>
  </bs:refreshable>
</form>
</div>
</c:when>
<c:otherwise>
<p class="resultsTitle">
  No issues are found related to the build configuration changes.<bs:help file="Integrating+TeamCity+with+Issue+Tracker"/>
  <authz:authorize projectId="${buildType.projectExternalId}" allPermissions="EDIT_PROJECT">
    <c:set var="configUrl">
      <admin:editProjectLink projectId="${buildType.projectExternalId}" addToUrl="&tab=issueTrackers" withoutLink="true"/>
    </c:set>
    Configure <a href="${configUrl}" title="Click to configure issue tracker settings">issue tracker settings</a>.
  </authz:authorize>
</p>
</c:otherwise>
</c:choose>
<script type="text/javascript">
  BS.Branch.baseUrl = "${url}";
</script>
