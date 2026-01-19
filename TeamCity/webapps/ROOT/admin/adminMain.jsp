<%@ include file="/include-internal.jsp"

%><jsp:useBean id="adminOverviewBean" scope="request" type="jetbrains.buildServer.controllers.admin.GroupedExtensionsBean"
/><bs:page disableScrollingRestore="true" isAdmin="${true}" moveAdminBreadcrumbs="${true}">
  <jsp:attribute name="head_include">
    <script type="text/javascript">
      <admin:projectPathJS startProject="${null}" currentTitle="${adminOverviewBean.selectedExtension.tabTitle}" startAdministration="${true}"/>

      (function() {
        var tabTitle = '<c:out value="${adminOverviewBean.selectedExtension.tabTitle}"/> \u2014 TeamCity';

        if (document.title.indexOf(tabTitle) == -1) {
          document.title = document.title.replace(/TeamCity$/, tabTitle);
        }
      })();
    </script>
    <bs:linkCSS>
      /css/pager.css
      /css/admin/adminMain.css
      /css/admin/serverConfig.css
      /css/profilePage.css
      /css/filePopup.css
    </bs:linkCSS>
    <bs:linkScript>
      /js/bs/serverConfig.js
      /js/bs/pauseProject.js
      /js/bs/pin.js
    </bs:linkScript>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <table id="admin-container">
      <tr>
        <td class="admin-sidebar" rowspan="2">
          <b class="admin-menu-title">Administration</b>
          <aside>
            <ext:showSidebar extensions="${adminOverviewBean.extensions}"
                             selectedExtension="${adminOverviewBean.selectedExtension}"
                             urlPrefix="/admin/admin.html"/>
            <div class="admin-menu__bg"></div>
          </aside>
        </td>
        <td class="no-padding"></td>
      </tr>
      <tr>
        <td class="admin-content">
          <bs:main>
            <div id="adminBreadcrumbsWrapper">
              <bs:breadcrumbs admin="true" />
            </div>
            <bs:unprocessedMessages/>
            <div id="tabsContainer4" class="simpleTabs clearfix"></div>
            <ext:includeExtension extension="${adminOverviewBean.selectedExtension}"/>
          </bs:main>
        </td>
      </tr>
    </table>
  </jsp:attribute>
</bs:page>
