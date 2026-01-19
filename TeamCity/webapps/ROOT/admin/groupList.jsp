<%@ page import="jetbrains.buildServer.controllers.profile.AuthorityRolesBean" %>
<%@ page import="jetbrains.buildServer.groups.UserGroupManager" %>
<%@ page import="jetbrains.buildServer.serverSide.auth.RolesHolder" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<c:set var="encodedPageUrl"><%=WebUtil.encode(pageUrl)%></c:set>
<c:set var="maxKeyLength" value="<%=UserGroupManager.MAX_GROUP_KEY_LENGTH%>"/>
<jsp:useBean id="groupsBean" type="jetbrains.buildServer.controllers.admin.groups.GroupsBean" scope="request"/>
<c:set var="currentTab" value="groups"/>

<c:set var="pageTitle" value="Groups" scope="request"/>
<bs:refreshable containerId="groupList" pageUrl="${pageUrl}">
  <c:set var="groups" value="${groupsBean.groups}"/>
  <c:set var="numGroups" value="${fn:length(groups)}"/>

  <bs:messages key="groupCreated"/>
  <bs:messages key="groupAttached"/>
  <bs:messages key="groupDeleted"/>
  <bs:messages key="groupNotFound"/>

  <c:if test="${afn:permissionGrantedGlobally('CREATE_USERGROUP')}">
    <div><forms:addButton onclick="BS.CreateGroupDialog.showDialog(); return false">Create new group</forms:addButton></div>
  </c:if>

  <table class="groupListHeader">
    <tr>
      <td class="groupStats">
        <c:if test="${empty groups}"><p>There are no groups.</p></c:if>
        <c:if test="${not empty groups}">
        <p>There <bs:are_is val="${numGroups}"/> <strong>${numGroups}</strong> group<bs:s val="${numGroups}"/> created.</p>
        </c:if>
      </td>
      <authz:authorize anyPermission="VIEW_ALL_USERS">
        <td class="groupTree">
          <c:if test="${not empty groups}">
            <p class="icon_before icon16 blockHeader collapsed" id="idgroupsTree">
              Groups Tree
            </p>

            <div id="groupsTree" class="groupTreeContainer" style="${util:blockHiddenCss(pageContext.request, "groupsTree", true)}">
              <bs:printTree treePrinter="${groupsBean.editableGroupTree}"/>
            </div>
            <script type="text/javascript">
              <l:blockState blocksType="Block_idgroupsTree"/>
              new BS.BlocksWithHeader('idgroupsTree');
            </script>
          </c:if>
        </td>
      </authz:authorize>
    </tr>
  </table>

  <div>
    <c:if test="${not empty groups}">
    <%--@elvariable id="serverSummary" type="jetbrains.buildServer.web.openapi.ServerSummary"--%>
    <l:tableWithHighlighting highlightImmediately="true" className="dark sortable groupsTable borderBottom">
      <tr>
        <th class="groupName">Name</th>
        <th class="groupDescription">Description</th>
        <th class="parentGroups">Parent Groups</th>
        <c:choose>
          <c:when test="${serverSummary.perProjectPermissionsEnabled}">
            <th class="groupRoles">Roles</th>
          </c:when>
          <c:otherwise>
            <th class="groupRoles">Admin Group</th>
          </c:otherwise>
        </c:choose>
        <th class="groupUsers">Users</th>
        <authz:authorize anyPermission="DELETE_USERGROUP">
        <th class="actions"></th>
        </authz:authorize>
      </tr>
      <c:forEach items="${groups}" var="group">
        <c:set var="onclick" value=""/>
        <c:if test="${group.editable}">
          <c:set var="onclick">onclick="BS.openUrl(event, '<bs:editGroupLink group="${group}" noLink="true"/>')"</c:set>
        </c:if>
        <c:set var="highlight">highlight</c:set>
        <tr>
          <td class="${highlight}" ${onclick}>
            <bs:editGroupLink group="${group}"><c:out value="${group.name}"/></bs:editGroupLink>
          </td>
          <td class="${highlight}" ${onclick}><c:out value="${group.description}"/></td>
          <td class="${highlight}" ${onclick}>
            <c:set var="groupsNum" value="${group.parentGroupsCount}"/>
            <c:set var="escapedGroupKey"><bs:escapeForJs text="${group.key}" forHTMLAttribute="true"/></c:set>
            <bs:popupControl showPopupCommand="BS.ParentGroupsPopup.showGroupParentGroups(this, '${escapedGroupKey}')"
                             hidePopupCommand="BS.ParentGroupsPopup.hidePopup()"
                             stopHidingPopupCommand="BS.ParentGroupsPopup.stopHidingPopup()"
                             controlId="groupParents:${escapedGroupKey}"><bs:editGroupLink group="${group}"><c:choose><c:when test="${groupsNum > 0}">View groups (${groupsNum})</c:when><c:otherwise>No groups</c:otherwise></c:choose></bs:editGroupLink></bs:popupControl>
          </td>
          <c:choose>
            <c:when test="${serverSummary.perProjectPermissionsEnabled}">
              <td class="${highlight}" ${onclick}>
                <c:set var="rolesCount" value='${group.rolesCount}'/>
                <c:set var="inheritedRolesCount" value='${group.numberOfInheritedRoles}'/>
                <bs:popupControl showPopupCommand="BS.AuthorityRolesPopup.showPopup(this, 'group:${escapedGroupKey}')"
                                 hidePopupCommand="BS.AuthorityRolesPopup.hidePopup()"
                                 stopHidingPopupCommand="BS.AuthorityRolesPopup.stopHidingPopup()"
                                 controlId="groupRoles:${escapedGroupKey}"><bs:editGroupLink group="${group}" tab="groupRoles"><c:choose><c:when test="${rolesCount + inheritedRolesCount> 0}">View roles (${rolesCount}<c:if test="${inheritedRolesCount > 0}">/${inheritedRolesCount}</c:if>)</c:when><c:otherwise>No roles</c:otherwise></c:choose></bs:editGroupLink></bs:popupControl>
              </td>
            </c:when>
            <c:otherwise>
              <td class="${highlight}" ${onclick}>
                <c:if test="${group.systemAdministratorRoleGranted}">Admin</c:if>
              </td>
            </c:otherwise>
          </c:choose>
          <bs:allUsersGroup group="${group}">
            <jsp:attribute name="ifAllUsersGroup">
              <td colspan="2" class="${highlight}" ${onclick}>contains all users, cannot be deleted</td>
            </jsp:attribute>
            <jsp:attribute name="ifUsualGroup">
              <td class="${highlight}" ${onclick}>
                <c:set var="usersCount" value="${group.directUsersCount}"/>
                <bs:popupControl showPopupCommand="BS.GroupUsersPopup.showPopup(this, '${escapedGroupKey}')"
                                 hidePopupCommand="BS.GroupUsersPopup.hidePopup()"
                                 stopHidingPopupCommand="BS.GroupUsersPopup.stopHidingPopup()"
                                 controlId="groupUsers:${escapedGroupKey}"><bs:editGroupLink group="${group}" tab="groupUsers"><c:choose><c:when test="${usersCount > 0}">View users (${usersCount})</c:when><c:otherwise>No users</c:otherwise></c:choose></bs:editGroupLink></bs:popupControl>
              </td>
              <authz:authorize anyPermission="DELETE_USERGROUP">
              <td class="actions edit last">
                  <c:choose>
                    <c:when test="${group.canDelete}">
                        <a href="#" onclick="BS.GroupActions.deleteGroup('${escapedGroupKey}', ${group.allUsersCount}, function() {BS.GroupActions.refreshGroupList()}); return false">Delete</a>
                    </c:when>
                    <c:otherwise>
                        <span>Delete</span>
                    </c:otherwise>
                  </c:choose>
              </td>
              </authz:authorize>
            </jsp:attribute>
          </bs:allUsersGroup>
        </tr>
      </c:forEach>
    </l:tableWithHighlighting>
    </c:if>
  </div>

<c:url var="action" value="/admin/action.html?createGroup=true"/>
<bs:modalDialog formId="addGroup" title="Create New Group" action="${action}" closeCommand="BS.CreateGroupDialog.close()" saveCommand="BS.CreateGroupForm.submit()" dialogClass="modalDialog_small">
  <span class="error" id="error_createError"></span>

  <label for="groupName" class="tableLabel">Name:<l:star/></label>
  <forms:textField name="groupName" value="" maxlength="255" onchange="generateKey(this.value)" className="mediumField"/>
  <span class="error" id="error_groupName"></span>
  <div class="clr spacing"></div>

  <label for="groupCode" class="tableLabel">Group Key:<l:star/></label>
  <forms:textField name="groupCode" value="" maxlength="80" onchange="this._modified = true" onfocus="generateKey($('groupName').value)" className="mediumField"/>
  <span class="error" id="error_groupCode"></span>
  <div class="clr spacing"></div>

  <label for="groupDescription" class="tableLabel">Description:</label>
  <forms:textField name="groupDescription" value="" maxlength="2000" className="mediumField"/>
  <div class="clr spacing"></div>

  <br/>
  <admin:_attachToGroups attachToGroupsBean="${groupsBean.attachNewGroupBean}" formId="addGroup"/>

  <div class="popupSaveButtonsBlock">
    <forms:submit label="Create"/>
    <forms:cancel onclick="BS.CreateGroupDialog.close()"/>
    <forms:saving id="addGroupProgress"/>
  </div>
  <script type="text/javascript">
    function generateKey(name) {
      var groupCode = $('groupCode');
      if (groupCode._modified && groupCode.value.length > 0) return;

      var upperCase = name.toUpperCase();
      var codePrefix = upperCase.replace(/[^A-Z_0-9]+/g, "_");
      codePrefix = codePrefix.replace(/[_]+/, "_");

      var codeSuffix = "";
      if ("_" == codePrefix) {
        codePrefix = "GROUP";
        codeSuffix = "_1";
      }
      var code = codePrefix + codeSuffix;
      if (code.length > ${maxKeyLength}) {
        code = code.substring(0, ${maxKeyLength});
      }
      groupCode.value = code;
    }
  </script>
</bs:modalDialog>
</bs:refreshable>

<jsp:include page="/admin/attachToGroups.html"/>
