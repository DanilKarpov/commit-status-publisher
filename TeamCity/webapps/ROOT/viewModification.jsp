<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %><%@
    include file="include-internal.jsp" %><%@
    taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %><%@
    taglib prefix="tags" tagdir="/WEB-INF/tags/tags" %><%@
    taglib prefix="ch" tagdir="/WEB-INF/tags/myChanges" %><%@
    taglib prefix="afn" uri="/WEB-INF/functions/authz"%><%@
    taglib prefix="user" uri="/WEB-INF/functions/user"
%>
<%--@elvariable id="extensionTab" type="jetbrains.buildServer.web.openapi.CustomTab"--%>
<jsp:useBean id="modification" type="jetbrains.buildServer.vcs.SVcsModification" scope="request"/>
<jsp:useBean id="changeStatus" type="jetbrains.buildServer.vcs.ChangeStatus" scope="request"/>
<jsp:useBean id="filteredStatus" type="jetbrains.buildServer.controllers.changes.VcsModificationController.FilteredStatus" scope="request"/>
<jsp:useBean id="buildTypeId" type="java.lang.String" scope="request"/>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>

<c:set var="personalIcon">
  <c:if test="${modification.personal}"><bs:personalChangesIcon1 mod="${modification}"/>&nbsp;</c:if>
</c:set>
<c:set var="whenDate"><bs:date value="${modification.vcsDate}" no_span="true"/></c:set>
<c:set var="whenDate" value='${fn:replace(whenDate, "&nbsp;", " ")}'/>

<c:set var="tab_title">Change details: <bs:changeCommitters modification="${modification}" no_tooltip="true" no_avatar="true"/> on ${whenDate}</c:set>
<c:set var="page_title">Change details: <bs:changeCommitters modification="${modification}" no_tooltip="true" avatarSize="${28}"/> on ${whenDate}</c:set>

<bs:page>
<jsp:attribute name="page_title">
  ${tab_title}
</jsp:attribute>
<jsp:attribute name="head_include">
  <bs:linkCSS>
    /css/settingsTable.css
    /css/statusTable.css
    /css/progress.css
    /css/modificationListTable.css
    /css/filePopup.css
    /css/viewModification.css
    /css/buildQueue.css
    /css/pager.css
  </bs:linkCSS>
  <bs:linkScript>
    /js/bs/blocks.js
    /js/bs/blocksWithHeader.js
    /js/bs/blockWithHandle.js
    /js/bs/changesBlock.js
    /js/bs/collapseExpand.js

    /js/bs/runningBuilds.js
    /js/bs/testGroup.js

    /js/bs/viewModification.js
    /js/bs/vcsSettings.js
  </bs:linkScript>

  <script type="text/javascript">
    BS.Navigation.items = [
      {
        title: "<bs:escapeForJs text="${personalIcon}${page_title}" forHTMLAttribute="false"/>",
        selected: true
      }
    ];

    ReactUI.setActivePageId('changes');

  </script>
  <bs:sakuraReleaseBanner change="${modification}" />
</jsp:attribute>

<jsp:attribute name="quickLinks_include">
  <bs:openInSakuraUI change="${modification}" />
</jsp:attribute>

<jsp:attribute name="body_include">
  <div style="display:none;">
    <!-- Set statusTableStyle variable -->
    <ch:statusTableStyle changeStatus="${changeStatus}"/>
  </div>
  <table id="statusTable" class="statusTable ${statusTableStyle}">
    <tr>
      <td class="caption changeCommentCaption">
        Comment:
      </td>
      <td style="width: 45%;">
        <div class="changeComment">
          <c:choose>
            <c:when test="${empty modification.description}">
              <bs:out value="No comment"/>
            </c:when>
            <c:otherwise>
              <%--@elvariable id="buildType" type="jetbrains.buildServer.serverSide.SBuildType"--%>
              <c:choose>
                <c:when test="${buildType != null}">
                  <bs:out value="${fn:trim(modification.description)}" resolverContext="${buildType}"/>
                </c:when>
                <c:otherwise>
                  <bs:out value="${fn:trim(modification.description)}" resolverContext="${modification}"/>
                </c:otherwise>
              </c:choose>
            </c:otherwise>
          </c:choose>
          <c:if test="${afn:canEditVcsChange(modification) and not modification.personal}">
             <a href="#" class="edit-icon" onclick="BS.EditModificationDescriptionDialog.showDialog(); return false;"
                   title="Edit modification description"
                ><i class="icon-edit"></i></a>
          </c:if>
        </div>
      </td>
      <td class="caption right">
        Status:
      </td>
      <td>
        <bs:changeBuildsSummary changeStatus="${filteredStatus}"/>
      </td>
    </tr>
    <tr>
      <td class="caption">
        Revision:
      </td>
      <td>
        <span class="revisionNum">
          <c:if test="${modification.personal}">
            ${whenDate} <!-- displayVersion for personal change returns date but in server timezone, here we want to show date in user timezone -->
          </c:if>
          <c:if test="${not modification.personal}">
            <c:out value="${modification.displayVersion}"/>
          </c:if>
        </span>
      </td>
      <c:choose>
        <c:when test="${modification.personal && modification.personalChangeInfo.commitType.commit}">

          <td class="caption right">
            Commit decision:
          </td>
          <td>
              ${modification.personalChangeInfo.commitStatusText}
          </td>

        </c:when>
        <c:when test="${not modification.personal}">
          <td class="caption right">
            VCS Root<bs:s val="${fn:length(vcsRoots)}"/>:
          </td>
          <td>
            <c:forEach var="root" items="${vcsRoots}" varStatus="pos"
                ><c:set var="cssClass"
                ><c:choose
                ><c:when test="${fn:length(vcsRoots) > 1 and root eq modification.vcsRoot.parent}">currentVcsRoot</c:when
                ><c:otherwise></c:otherwise
                ></c:choose
                ></c:set>
              <c:set var="vcsRootName"
                  ><c:choose
                  ><c:when test="${afn:canEditVcsRoot(root)}"
                  ><admin:editVcsRootLink vcsRoot="${root}" editingScope="" cameFromUrl="${pageUrl}"
                  ><span class="${cssClass}"><c:out value="${root.name}"
                  /></span></admin:editVcsRootLink
                  ></c:when
                  ><c:otherwise
                  ><span class="${cssClass}"><c:out value="${root.name}"
                  /></span></c:otherwise
                  ></c:choose
                  ></c:set
                  ><c:choose
                  ><c:when test="${pos.last}"><span style="white-space: nowrap">${vcsRootName} <em>(${root.vcsDisplayName})</em></span></c:when
                  ><c:otherwise><span style="white-space: nowrap;">${vcsRootName} <em>(${root.vcsDisplayName}),</em></span></c:otherwise
                  ></c:choose>
            </c:forEach>
          </td>
        </c:when>
        <c:otherwise>
          <td colspan="2">&nbsp;</td>
        </c:otherwise>
      </c:choose>
    </tr>
    <c:if test="${fn:length(modification.parentRevisions) gt 0}">
    <tr>
      <td class="caption">
        Parent revisions:
      </td>
      <td>
        <c:set var="parentMods" value="${modification.parentModifications}"/>
        <c:forEach items="${modification.parentRevisions}" var="rev" varStatus="pos">
          <c:set var="modId" value=""/>
          <c:forEach items="${parentMods}" var="m">
            <c:if test="${m.version eq rev}">
              <c:set var="modId" value="${m.id}"/>
            </c:if>
          </c:forEach>
          <c:choose>
            <c:when test="${modId eq ''}">
              <span class="revisionNum"><c:out value="${rev}"/></span><c:if test="${not pos.last}">, </c:if>
            </c:when>
            <c:otherwise>
              <c:url var="revLink" value="/viewModification.html?modId=${modId}&tab=vcsModificationFiles"/>
              <a href="${revLink}" title="Click to view change details"><span class="revisionNum"><c:out value="${rev}"/></span></a><c:if test="${not pos.last}">, </c:if>
            </c:otherwise>
          </c:choose>
        </c:forEach>
      </td>
      <td colspan="2">&nbsp;</td>
    </tr>
    </c:if>
    <tr>
      <td class="caption">
        User:
      </td>
      <td colspan="3">
        <c:set var="committers" value="${modification.committers}"/>
        <c:if test="${empty committers}">
          <em>Unknown (none of TeamCity users defined <strong><c:out value="${modification.userName}"/></strong> username in their VCS username settings)</em>
          <c:if test="${afn:permissionGrantedGlobally('CHANGE_OWN_PROFILE')}">
            <a title="Add VCS username &quot;<c:out value="${modification.userName}"/>&quot; to my profile"
               href="javascript:;" onclick="BS.VcsUsername.viewModificationAddVcsName(${modification.id}, '<bs:escapeForJs text="${modification.userName}" forHTMLAttribute="true"/>');">it's me!</a>
            <forms:saving id="addVcsNameProgress" className="progressRingInline"/>
          </c:if>
        </c:if>
        <c:forEach items="${committers}" var="committer" varStatus="pos"><c:out value="${committer.extendedName}"/><c:if test="${not pos.last}">, </c:if></c:forEach
        ><c:if test="${not empty committers}">, VCS username: <c:out value="${modification.userName}"/></c:if>
      </td>
    </tr>
  </table>

  <c:url value='/ajax.html' var="actionUrl"/>
  <bs:modalDialog formId="editModificationForm"
                  title="Edit change description"
                  action="${actionUrl}"
                  closeCommand="BS.EditModificationDescriptionDialog.close();"
                  saveCommand="BS.EditModificationDescriptionDialog.submit()">

    <div class="attentionComment">
      Here you can change the description in TeamCity only.
      You may consider changing it in the VCS as well, to avoid an ambiguity and inconsistency.
    </div>
    <br>
    <textarea name="modificationDescription" rows="5" cols="46" class="commentTextArea"><c:out value="${modification.description}"/></textarea>
    <input type="hidden" name="_action" value="setModificationDescription">
    <input type="hidden" name="modId" value="${modification.id}">
    <input type="hidden" name="personal" value="${modification.personal}">

    <div class="popupSaveButtonsBlock">
      <forms:submit label="Save description" id="VcsModificationSaveButton"/>
      <forms:cancel onclick="BS.EditModificationDescriptionDialog.close()"/>
      <forms:saving/>
    </div>

  </bs:modalDialog>


  <%@ include file="_changeTabs.jspf" %>
</jsp:attribute>
</bs:page>
