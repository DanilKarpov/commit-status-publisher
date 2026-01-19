<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="editGroupBean" type="jetbrains.buildServer.controllers.admin.groups.EditGroupBean" scope="request"/>

<c:set var="users" value="${editGroupBean.users}"/>
<c:set var="usersNum" value="${editGroupBean.groupDto.directUsersCount}"/>
<c:set var="canAddRemoveUsers" value="${editGroupBean.canAddToGroup}"/>

<bs:allUsersGroup group="${editGroupBean.groupDto}">
  <jsp:attribute name="ifAllUsersGroup">
    <strong><c:out value="${editGroupBean.groupDto.name}"/></strong> is a special group which contains all users.
  </jsp:attribute>
  <jsp:attribute name="ifUsualGroup">
    <bs:refreshable containerId="groupUsersContainer" pageUrl="${pageUrl}">
      <bs:messages key="usersUnassigned"/>
      <bs:messages key="usersAssigned"/>

      <c:if test="${canAddRemoveUsers}">
        <div style="margin: 0 0 1em">
          <c:set var="escapedgroupKey"><bs:escapeForJs text="${editGroupBean.groupDto.key}" forHTMLAttribute="true"/></c:set>
          <forms:addButton onclick="BS.AttachUsersToGroupDialog.showAttachDialog('${escapedgroupKey}'); return false">Add users to group</forms:addButton>
        </div>
      </c:if>

      <c:if test="${not canAddRemoveUsers}">
        <p class="note">You do not have enough permissions to add users to this group.</p>
      </c:if>
      <c:if test="${usersNum == 0}"><p class="note">There are no users added to this group.</p></c:if>
      <c:if test="${usersNum > 0}">
        <p class="note"><strong>${usersNum}</strong> user<bs:s val="${usersNum}"/> added to this group.</p>

        <c:url value="/admin/action.html" var="action"/>
        <form id="unassignUsersForm" action="${action}" onsubmit="return BS.UnassignUsersForm.submit()">
          <table class="settings groupUsersTable sortable">
            <tr>
              <th class="username sortable"><span id="SORT_BY_USERNAME">Username</span></th>
              <th class="sortable"><span id="SORT_BY_NAME">Name</span></th>
              <authz:authorize anyPermission="VIEW_USER_PROFILE, CHANGE_USER">
                <th class="email sortable" >
                  <bs:allEmails users="${users}"/><span id="SORT_BY_EMAIL">Email</span>
                </th>
              </authz:authorize>
              <c:if test="${canAddRemoveUsers}">
              <th class="unassign">
                <forms:checkbox name="selectAll"
                                onmouseover="BS.Tooltip.showMessage(this, {shift: {x: 10, y: 20}, delay: 600}, 'Click to select / unselect all users')"
                                onmouseout="BS.Tooltip.hidePopup()"
                                onclick="if (this.checked) BS.UnassignUsersForm.selectAll(true); else BS.UnassignUsersForm.selectAll(false)"/>
              </th>
              </c:if>
            </tr>
            <c:forEach items="${users}" var="user">
              <tr>
                <td><bs:editUserLink user="${user}"/></td>
                <td><bs:avatar user="${user}"/><c:out value="${user.name}"/></td>
                <authz:authorize anyPermission="VIEW_USER_PROFILE, CHANGE_USER">
                  <td><c:out value="${user.email}"/></td>
                </authz:authorize>
                <c:if test="${canAddRemoveUsers}">
                  <td class="unassign">
                    <forms:checkbox name="unassign" value="${user.id}" disabled="${currentUser.id == user.id}"/>
                  </td>
                </c:if>
              </tr>
            </c:forEach>
          </table>

          <c:if test="${canAddRemoveUsers}">
            <div class="saveButtonsBlock saveButtonsBlockRight">
              <forms:saving id="unassignInProgress" className="progressRingInline"/>
              <input class="btn" type="submit" name="detachUsers" value="Remove from group"/>
            </div>
          </c:if>

          <script type="text/javascript">
            (function() {
              <c:forEach items="${editGroupBean.sortOptions}" var="sortOption">
              var sortOption = $('${sortOption}');
              if (sortOption) {
                <c:if test="${editGroupBean.sortBy == sortOption}">
                  sortOption.className = sortOption.className + ' ${editGroupBean.sortAsc ? "sortedAsc" : "sortedDesc"}';
                </c:if>
                sortOption.on("click", BS.UnassignUsersForm.reSort.bindAsEventListener(BS.UnassignUsersForm));
              }
              </c:forEach>
            })();
          </script>

          <input type="hidden" name="groupCode" value="<c:out value='${editGroupBean.groupDto.key}'/>"/>
          <input type="hidden" name="sortBy" value="${editGroupBean.sortBy}"/>
          <input type="hidden" name="sortAsc" value="${editGroupBean.sortAsc}"/>
        </form>
      </c:if>

      <jsp:include page="/admin/attachUsersToGroup.html"/>
    </bs:refreshable>
  </jsp:attribute>
</bs:allUsersGroup>
