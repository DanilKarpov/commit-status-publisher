<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:useBean id="editGroupBean" type="jetbrains.buildServer.controllers.admin.groups.EditGroupBean" scope="request"/>
<c:set var="currentTab" value="${selectedTab.pluginName}"/>
<c:choose>
  <c:when test="${currentTab == 'groupGeneralSettings'}"><c:set var="pageTitle" scope="request" value="Edit Group ${editGroupBean.group.name}"/></c:when>
  <c:when test="${currentTab == 'groupUsers'}"><c:set var="pageTitle" scope="request" value="Edit Users of Group ${editGroupBean.group.name}"/></c:when>
  <c:when test="${currentTab == 'groupNotifications'}"><c:set var="pageTitle" scope="request" value="Edit Notification Rules of Group ${editGroupBean.group.name}"/></c:when>
  <c:otherwise><c:set var="pageTitle" scope="request" value="Edit Roles of ${editGroupBean.group.name}"/></c:otherwise>
</c:choose>
<bs:page isAdmin="${true}" moveAdminBreadcrumbs="${empty editGroupBean.group.key}">
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/userListFilter.css
      /css/admin/userGroups.css
      /css/userRoles.css
      /css/admin/adminMain.css
      /css/notificationRules.css
      /css/profilePage.css
      /css/settingsBlock.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/profile.js
      /js/bs/userGroups.js
      /js/bs/queueLikeSorter.js
      /js/bs/notificationRules.js
    </bs:linkScript>
    <script type="text/javascript">
      BS.Navigation.items = [
        <forms:cameBackNav cameFromSupport="${editGroupBean.cameFromSupport}"/>,
        {title: '<bs:escapeForJs text="${editGroupBean.group.name}" forHTMLAttribute="true"/>', selected: true}
      ];
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <table id="admin-container">
      <tr>
        <c:url var="baseUrl" value='/admin/editGroup.html?init=1&groupCode=${util:urlEscape(editGroupBean.group.key)}'/>
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
            <jsp:include page="${selectedTab.includeUrl}"/>
          </bs:main>
        </td>
      </tr>
    </table>

  </jsp:attribute>
</bs:page>
