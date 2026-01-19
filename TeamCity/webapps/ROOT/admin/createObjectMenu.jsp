<%@ include file="/include-internal.jsp"%>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="jetbrains.buildServer.web.util.CameFromSupport" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ taglib prefix="util" uri="/WEB-INF/functions/util" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.SUser" scope="request"/>
<c:set var="cameFromUrl" value='<%=WebUtil.encode(CameFromSupport.getUrlForRedirect(request, null))%>'/>
<%--@elvariable id="showMode" type="java.lang.String"--%>
<%--@elvariable id="pageUrl" type="java.lang.String"--%>
<c:choose>
  <c:when test="${showMode == 'createProjectMenu'}">
    <c:set var="title" value="Create Project"/>
  </c:when>
  <c:when test="${showMode == 'createBuildTypeMenu'}">
    <c:set var="title" value="Create Build Configuration"/>
  </c:when>
</c:choose>

<bs:page disableScrollingRestore="true">
  <jsp:attribute name="page_title">${title}</jsp:attribute>
  <jsp:attribute name="head_include">
    <bs:linkCSS>
      /css/admin/adminMain.css
    </bs:linkCSS>
    <script type="text/javascript">
      <bs:trimWhitespace>
        <admin:projectPathJS startProject="${project}" startAdministration="${true}"/>

        BS.Navigation.items.push({
          title: '${title}',
          url: '${pageUrl}',
          selected: true
        });

      BS.CreateObjectMenu = {
        ready: false,
        extensionsToWaitFor: new Set(),

        waitForExtension: function (extension) {
          this.extensionsToWaitFor.add(extension);
        },

        extensionIsReady: function (extension) {
          this.extensionsToWaitFor.delete(extension);
          if (this.extensionsToWaitFor.size == 0 && this.ready) {
            initOptionsAndAutoExpand();
          }
        }
      };

      function toggleContainer(eventEl, url, staticContainerId) {
        var container = $j('.createFormContainer');

        if (url && url === container.data('url')) {
          return; // do not reload already opened option
        }

        if (url == null && staticContainerId != null) {
          url = '#' + staticContainerId;
        }

        if (url == null) {
          url = '';
        }


        $j('.createOption').removeClass('expanded');
        $j('.createOption').addClass('collapsed');

        if (url !== '') {
          $j(eventEl).removeClass('collapsed');
          $j(eventEl).addClass('expanded');
        }
        container.data('url', url);

        if (url !== '' && !url.startsWith('#')) {
          container.html('<span><i class="icon-refresh icon-spin ring-loader-inline progressRing progressRingDefault" style="float:none"></i> Loading...</span>');
          BS.ajaxUpdater(container[0], url, {method: 'get', evalScripts: true});
        } else {
          if (staticContainerId) {
            container.html($j('#' + staticContainerId).html());
          } else {
            container.html('');
          }
        }

        container.show(100);
      }

      function refreshCurrentContainer() {
        var container = $j('.createFormContainer');
        var url = container.data('url');

        $j(container).html('<span><i class="icon-refresh icon-spin ring-loader-inline progressRing progressRingDefault" style="float:none"></i> Loading...</span>');
        BS.ajaxUpdater($j(container)[0], url, {method: 'get', evalScripts: true});
      }

      $j(document).ready(function() {
        BS.CreateObjectMenu.ready = true;
        if (BS.CreateObjectMenu.extensionsToWaitFor.size == 0) {
          initOptionsAndAutoExpand();
        }
      });

      function initOptionsAndAutoExpand() {
        if (BS.CreateObjectMenu.initialized) {
          return;
        }

        BS.CreateObjectMenu.initialized = true;

        $j(".createOption").click(function() {
          var url = $j(this).data('url');
          var containerId = $j(this).data('content');

          if ($j(this).prevAll('a').length > 0 && url) {
            var extensionName = $j(this).prevAll('a')[0].name;
          }
          toggleContainer(this, url, containerId);

          if (extensionName) {
            BS.User.setProperty("lastSelectedCreateObjectOption", extensionName);
            document.location.hash = extensionName;
          }
        });


        var autoExpand = '<c:out value="${param['autoExpand']}"/>';
        const autoExpandId = '<bs:forJs>${param['autoExpandId']}</bs:forJs>';
        if (!autoExpand) {
          autoExpand = "${ufn:getPropertyValue(currentUser, 'lastSelectedCreateObjectOption')}";
        }
        if (autoExpandId) {
          $j('#' + autoExpandId).click();
        } else if (autoExpand
            && $j("a[name='" + autoExpand + "']").nextAll('.createOption')[0]
            && $j("a[name='" + autoExpand + "']").nextAll('.createOption').first().hasClass('readyToUseOption')) {
          $j("a[name='" + autoExpand + "']").nextAll('.createOption')[0].click();
        } else {
          if ($j(".createOption.preferableOption").length > 0) {
            $j(".createOption.preferableOption")[0].click();
          } else if ($j("a[name='createFromUrl']").nextAll('.createOption')[0]) {
            $j("a[name='createFromUrl']").nextAll('.createOption')[0].click();
          }
        }
      };
      </bs:trimWhitespace>

      ReactUI.setActivePageId('projects');
    </script>
    <style type="text/css">
      div.menuList {
        margin-left: -5px;
        width: 100%;
      }

      .createOption {
        padding: 1em;
        vertical-align: top;

        border: 1px solid var(--ring-line-color, #dfe5eb);

        display: inline-block;
        background-color: var(--ring-content-background-color, #fff);
        width: 21%;

        margin: .5em;
        cursor: pointer;
      }

      .createOption:hover {
        text-decoration: none;
      }

      div.menuList h3 {
        font-size: 120%;
        color: var(--ring-text-color, #1f2326);
        padding: 5px 5px 5px 0;
        font-weight: normal;
        background-color: transparent;
        margin: 0;
        border-bottom: none;
      }

      .menuList.menuList_create {
        display: flex;
        flex-wrap: wrap;
      }

      .menuList_create .createOption {
        display: flex;
        justify-content: center;
        align-items: center;
        flex-direction: column;
        flex-shrink: 0;

        text-align: center;
      }

      .ua-ie10-below .menuList_create .createOption {
        height: 4.5em;
      }

      div.menuList i.tc-icon {
        margin-right: 5px;
      }

      div.menuList .createOption:hover {
        background-color: var(--ring-secondary-background-color, #f7f9fa);
      }

      div.menuList .createOption.expanded {
        background-color: var(--ring-secondary-background-color, #f7f9fa);
        cursor: auto;
      }

      .createOption__second-line {
        padding: 5px 0;
      }

      .createFormContainer {
        margin-top: 2em;
      }

      .createFormContainer > div {
        padding-top: 1em;
      }
    </style>
  </jsp:attribute>
  <jsp:attribute name="body_include">
    <div class="menuList menuList_create">
      <c:choose>
        <c:when test="${showMode == 'createProjectMenu'}">
          <c:url value='/admin/createObjectFromUrl.html?init=1&objectType=PROJECT&parentId=${project.externalId}&embedded=true' var="createFromUrl"/>
          <a name="createFromUrl"></a>
          <a href="#createFromUrl" class="createOption readyToUseOption" data-url="${createFromUrl}">
            <h3>From a repository URL</h3>
          </a>
        </c:when>
        <c:when test="${showMode == 'createBuildTypeMenu'}">
          <c:url value='/admin/createObjectFromUrl.html?init=1&objectType=BUILD_TYPE&parentId=${project.externalId}&embedded=true' var="createFromUrl"/>
          <a name="createFromUrl"></a>
          <a href="#createFromUrl" class="createOption readyToUseOption" data-url="${createFromUrl}">
            <h3>From a repository URL</h3>
          </a>
        </c:when>
        <c:when test="${showMode == 'createCompositeBuildType'}">
          <c:set var="templateId" value=""/>
          <c:if test="${not empty param['templateId']}"><c:set var="templateId">&templateId=<c:out value="${param['templateId']}"/></c:set></c:if>
          <c:url value="/admin/createBuildType.html?projectId=${project.externalId}${templateId}&init=1&buildConfigurationType=COMPOSITE&cameFromUrl=${cameFromUrl}" var="createUrl"/>
          <script type="text/javascript">
            $j(document).ready(function() {
              toggleContainer(null, '${createUrl}');
            });
          </script>
        </c:when>
      </c:choose>

      <%--@elvariable id="readOnly" type="java.lang.Boolean"--%>
      <c:if test="${showMode ne 'createCompositeBuildType' and not readOnly}">
      <ext:forEachExtension placeId="<%=PlaceId.ADMIN_LIST_REPOSITORIES%>">
        <c:set var="extensions" value="${util:toSet(paramValues['extension'])}"/>
        <c:if test="${empty extensions or util:contains(extensions, extension.pluginName)}">
          <a name="${extension.pluginName}"></a>
          <ext:includeExtension extension="${extension}"/>
        </c:if>
      </ext:forEachExtension>
      </c:if>

      <c:choose>
        <c:when test="${showMode == 'createProjectMenu'}">
          <c:url value='/admin/createProject.html?init=1&parentId=${project.externalId}&embedded=true&cameFromUrl=${cameFromUrl}' var="createProjectUrl"/>
          <a name="createManually"></a>
          <a href="#createManually" class="createOption readyToUseOption" data-url="${createProjectUrl}" data-hint-container-id="create-project">
            <h3><i class="tc-icon icon-wrench"></i> Manually</h3>
          </a>
          <script>
            window.ReactUI.registerHint({
              id: 'create-project',
              name: 'Create Project',
              text: 'A project in TeamCity most often represents a software product or a group of products. It can contain subprojects and build configurations that produce, test, and deploy parts of the product. ' +
                'You can configure a project manually, or let TeamCity guess its main settings from a source repository URL. In any case, you will be able to adjust the settings later.',
              helpLink: BS.helpUrlPrefix + 'Creating+and+Editing+Projects',
              category: 'Create Entity'
            })
          </script>
        </c:when>
        <c:when test="${showMode == 'createBuildTypeMenu'}">
          <c:set var="templateId" value=""/>
          <c:if test="${not empty param['templateId']}"><c:set var="templateId">&templateId=<c:out value="${param['templateId']}"/></c:set></c:if>
          <c:url value="/admin/createBuildType.html?projectId=${project.externalId}${templateId}&init=1&cameFromUrl=${cameFromUrl}" var="createUrl"/>
          <a name="createManually"></a>
          <a href="#createManually" class="createOption readyToUseOption" data-url="${createUrl}" data-hint-container-id="create-build-configuration">
            <h3><i class="tc-icon icon-wrench"></i> Manually</h3>
          </a>
          <script>
            window.ReactUI.registerHint({
              id: 'create-build-configuration',
              name: 'Create Build Configuration',
              text: 'A build in TeamCity executes a certain job: builds a product, runs tests, or deploys the final application. A build configuration defines the settings of a build. ' +
                'You can set it up manually, or let TeamCity guess its main settings from your repository URL. In any case, you will be able to adjust the settings later.',
              helpLink: BS.helpUrlPrefix + 'Creating+and+Editing+Build+Configurations',
              category: 'Create Entity'
            })
          </script>

        </c:when>
      </c:choose>
    </div>
    <div class="createFormContainer"></div>
  </jsp:attribute>
</bs:page>
