<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>

<jsp:useBean id="adminEditUserForm" type="jetbrains.buildServer.controllers.admin.users.AdminEditUserForm" scope="request"/>
<c:choose>
  <c:when test="${currentTab == 'userGeneralSettings'}"><c:set var="pageTitle" scope="request"
                                                               value="Edit General Settings of ${adminEditUserForm.editee.descriptiveName}"/></c:when>
  <c:when test="${currentTab == 'userRoles'}"><c:set var="pageTitle" scope="request" value="Edit Roles of ${adminEditUserForm.editee.descriptiveName}"/></c:when>
  <c:when test="${currentTab == 'userGroups'}"><c:set var="pageTitle" scope="request" value="Edit Groups of ${adminEditUserForm.editee.descriptiveName}"/></c:when>
  <c:when test="${currentTab == 'vcsUsernames'}"><c:set var="pageTitle" scope="request" value="Edit VCS Usernames of ${adminEditUserForm.editee.descriptiveName}"/></c:when>
  <c:when test="${currentTab == 'userNotifications'}"><c:set var="pageTitle" scope="request"
                                                               value="Edit Notification Rules of ${adminEditUserForm.editee.descriptiveName}"/></c:when>
  <c:when test="${currentTab == 'accessTokens'}"><c:set var="pageTitle" scope="request"
                                                               value="Edit Access Tokens of ${adminEditUserForm.editee.descriptiveName}"/></c:when>
  <c:otherwise><c:set var="pageTitle" scope="request" value="View Groups of ${adminEditUserForm.editee.descriptiveName}"/></c:otherwise>
</c:choose>
<bs:page isAdmin="${true}" moveAdminBreadcrumbs="${false}">
<jsp:attribute name="head_include">
  <bs:linkCSS>
    /css/profilePage.css
    /css/settingsBlock.css
    /css/userRoles.css
    /css/admin/adminMain.css
    /css/admin/userGroups.css
    /css/notificationRules.css
  </bs:linkCSS>
  <bs:linkScript>
    /js/bs/updateUser.js
    /js/bs/profile.js
    /js/bs/userGroups.js
    /js/bs/queueLikeSorter.js
    /js/bs/notificationRules.js
  </bs:linkScript>
  <script type="text/javascript">
    BS.Navigation.items = [
      {title: "Users", url: '<c:url value="/admin/admin.html?item=users"/>'},
      {title: '<bs:escapeForJs text="${adminEditUserForm.editee.descriptiveName}" forHTMLAttribute="true"/>', selected: true}
    ];
  </script>
</jsp:attribute>

  <jsp:attribute name="body_include">
    <table id="admin-container">
      <tr>
        <c:url var="baseUrl" value='/admin/editUser.html?init=1&userId=${adminEditUserForm.editee.id}'/>
        <td class="user-profile admin-sidebar compact">
          <aside>
            <c:forEach items="${tabs}" var="tab">
              <div class="item${tab == selectedTab ? ' active' : ''}">
                <a href="${baseUrl}&item=${tab.tabId}&init=1">${tab.tabTitle}</a>
              </div>
            </c:forEach>
            <div class="admin-menu__bg"></div>
          </aside>
        </td>
        <td class="admin-content" style="width: 100%;">
          <bs:main>
            <div id="adminBreadcrumbsWrapper">
            </div>
            <jsp:include page="${selectedTab.includeUrl}"/>
          </bs:main>
        </td>
      </tr>
    </table>
</jsp:attribute>

</bs:page>

<c:if test="${counterSet}">
  <script type="text/javascript">
    <c:if test="${notificationTabCounter > -1}">
    BS.UserProfile.updateTabCounter('Notification Rules', 'notificationRulesTabCounter', ${notificationTabCounter});
    </c:if>
    <c:if test="${accessTokensTabCounter > -1}">
    BS.UserProfile.updateTabCounter('Access Tokens', 'accessTokensTabCounter', ${accessTokensTabCounter});
    </c:if>
  </script>
</c:if>
