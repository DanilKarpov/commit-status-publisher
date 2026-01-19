<%@ page import="jetbrains.buildServer.web.util.WebUtil"
%><%@ include file="../include-internal.jsp"
%><%@ taglib prefix="ufn" uri="/WEB-INF/functions/user"
%>
<c:if test="${not empty param.iframe}">
  <!DOCTYPE html>
  <%--@elvariable id="snippet" type="jetbrains.buildServer.web.openapi.PageExtension"--%>
  <meta name="tc-csrf-token" content="${sessionScope['tc-csrf-token']}"/>
  <bs:polyfills/>
  <bs:jquery/>
  <bs:linkCSS>
    /css/FontAwesome/css/font-awesome.min.css
    /css/main.css
    /css/icons.css
    /css/tabs.css
    /css/buildLog/buildResultsDiv.css
    /css/testGroups.css
    /css/testList.css
    /css/testMetadata.css
    /css/investigation.css
    /css/statusChangeLink.css
    /css/tree/oldTree.css
    /css/tree/tree.css
    /css/projectHierarchy.css
    /css/tags.css

    /css/quickLinksPopUp.css
    /css/forms.css
    /css/runCustomBuild.css
    /css/issues.css
    /css/ellipsis.css

    /css/autocompletion.css

    /css/codemirror/codemirror.css
    /css/codemirror/codemirror-teamcity.css
    /css/codemirror/addon/hint/show-hint.css
  </bs:linkCSS>

  <bs:ua/>
  <bs:baseUri/>
  <bs:prototype/>
  <bs:commonFrameworks/>

  <bs:predefinedIntProps/>

  <bs:linkScript>
    <%-- BS - utility components --%>
    /js/bs/bs.js
    /js/bs/cookie.js
    /js/bs/resize.js
    /js/bs/position.js
    /js/bs/refresh.js

    <%-- BS - common components --%>
    /js/bs/tabs.js
    /js/bs/forms.js
    /js/bs/basePopup.js
    /js/bs/menuList.js
    /js/bs/modalDialog.js
    /js/bs/investigation.js
    /js/bs/changeBuildStatus.js
    /js/bs/tree.js
    /js/bs/issues.js
    /js/bs/pluginProperties.js
    /js/bs/serverLink.js
    /js/bs/activation.js
    /js/bs/datepicker.js
    /js/bs/tags.js
    /js/bs/backgroundLoader.js
    /js/bs/bs-clipboard.js
    /js/bs/blocks.js
    /js/bs/collapseExpand.js
    /js/bs/blockWithHandle.js
    /js/bs/blocksWithHeader.js

    <%-- BS - business logic --%>
    /js/bs/adminActions.js
    /js/bs/advancedOptions.js
    /js/bs/runBuild.js
    /js/bs/stopBuild.js
    /js/bs/customControl.js
    /js/bs/parameters.js
    /js/bs/editParameters.js
    /js/bs/branch.js
    /js/bs/vcsSettings.js

    /js/bs/toggleOverview.js

    /js/bs/pin.js
    /js/bs/buildComment.js

    /js/codemirror/lib/codemirror.js
    /js/codemirror/lib/codemirror-teamcity.js
    /js/codemirror/addon/edit/closetag.js
    /js/codemirror/addon/edit/matchbrackets.js
    /js/codemirror/addon/selection/active-line.js
    /js/codemirror/mode/xml/xml.js
    /js/codemirror/addon/mode/loadmode.js
    /js/codemirror/addon/mode/simple.js
    /js/codemirror/addon/hint/show-hint.js
    /js/bs/codemirror.js
  </bs:linkScript>

  <script>
    BS.helpUrlPrefix = '<bs:helpUrlPrefix/>';
    BS.feedbackUrl = '<bs:feedbackUrl/>';
  </script>

  <c:if test="${param.embedded}">
    <bs:linkScript>
      /js/iframeResizer/iframeResizer.contentWindow.js
    </bs:linkScript>
  </c:if>

  <bs:linkScript>
    /js/iframeResizer/iframeResizer.contentWindow.js
  </bs:linkScript>
  <style type="text/css">
    .blockHeader {
      display: none;
    }
    .collapsibleBlock {
      margin-left: -15px;
    }
  </style>
  <script type="application/javascript">
    window.addEventListener("load", function(){
       $j('.collapsibleBlock').css('display', 'block');
    });
  </script>
  <bs:reactUi/>
  <c:if test="${not empty currentUser}">
    <script>
      if (internalProps['teamcity.ui.darkTheme.adapter.enabled'] === true) {
        ReactUI.setGlobalTheme("${ufn:getPreferredTheme(currentUser)}")
      }
    </script>
  </c:if>
</c:if>
