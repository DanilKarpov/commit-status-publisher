<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="include-internal.jsp"
%><jsp:useBean id="modification" type="jetbrains.buildServer.vcs.VcsModification" scope="request"
/><jsp:useBean id="changedFile" type="jetbrains.buildServer.vcs.VcsChangeInfo" scope="request"
/><jsp:useBean id="ignoreSpaces" type="java.lang.Boolean" scope="request"
/><jsp:useBean id="currentUser" type="jetbrains.buildServer.users.SUser" scope="request"
/><c:set var="title" value="${changedFile.relativeFileName} diff"
/><c:set var="title"><c:out value="${title}"/></c:set
><c:set var="encodedFilename" value="<%=WebUtil.encode(changedFile.getFileName())%>"
/><c:set var="encodedRelativeFilename" value="<%=WebUtil.encode(changedFile.getRelativeFileName())%>"
/><bs:externalPage
  ><jsp:attribute name="page_title">${title}</jsp:attribute
    ><jsp:attribute name="head_include">
    <%--@elvariable id="changes" type="String"--%>
    <%--@elvariable id="styles" type="String"--%>
    <bs:linkCSS>
      /css/diffView.css
      /css/filePopup.css
      /css/forms.css
      /css/issues.css
      /css/highlight-idea.css
    </bs:linkCSS>

    <style type="text/css">
      ${styles}
    </style>

    <bs:linkScript>
      /js/bs/forms.js
      /js/bs/modalDialog.js
      /js/bs/activation.js
      /js/bs/issues.js
      /js/bs/vcsSettings.js
    </bs:linkScript>
    <bs:reactUi />
    <script>
      ReactUI.setGlobalTheme("${ufn:getPreferredTheme(currentUser)}")
    </script>
  </jsp:attribute>
  <jsp:attribute name="body_include">
  <%--@elvariable id="before" type="String"--%>
  <%--@elvariable id="after" type="String"--%>
<c:choose>
  <c:when test="${changedFile.type == 'CHANGED'}"><c:set var="chg" value="edited"/></c:when>
  <c:when test="${changedFile.type == 'ADDED'}"><c:set var="chg" value="added"/></c:when>
  <c:when test="${changedFile.type == 'REMOVED'}"><c:set var="chg" value="deleted"/></c:when>
  <c:when test="${changedFile.type == 'NOT_CHANGED'}"><c:set var="chg" value="unchanged"/></c:when>
</c:choose>

<c:set var="isActualModification" value="${modification.id >= 0}"/>
<c:if test="${isActualModification}">
  <c:set var="queryParams" value="modId=${modification.id}&personal=${modification.personal}"/>
  <c:set var="queryParams" value="${queryParams}&openFileLinksInSameTab=true&highlightChange=${encodedFilename}"/>
</c:if>

<c:if test="${!isActualModification}">
  <c:set var="chg" value="${changedFile.changeTypeName}"/>
</c:if>

<div id="mainContent">
  <div id="diffView">
    <div id="fileName">
        <%--@elvariable id="prevChange" type="String"--%>
        <%--@elvariable id="nextChange" type="String"--%>
      <c:if test="${isActualModification}">
      <span class="prevNextContainer">
        <c:choose>
          <c:when test="${empty prevChange}">
            <a class="prevNext prevNextDisabled" href="#">
              &larr;
            </a>
          </c:when>
          <c:otherwise>
            <c:url value='/diffView.html?id=${modification.id}&personal=${modification.personal}' var="prevDiffUrl">
              <c:param name="vcsFileName" value="${prevChange}"/>
            </c:url>
            <a class="prevNext" href="${prevDiffUrl}" title="Show previous file diff">
              &larr;
            </a>
          </c:otherwise>
        </c:choose>

        <c:choose>
          <c:when test="${empty nextChange}">
            <a class="prevNext prevNextDisabled" href="#">
              &rarr;
            </a>
          </c:when>
          <c:otherwise>
            <c:url value='/diffView.html?id=${modification.id}&personal=${modification.personal}' var="nextDiffUrl">
              <c:param name="vcsFileName" value="${nextChange}"/>
            </c:url>
            <a class="prevNext" href="${nextDiffUrl}" title="Show next file diff">
              &rarr;
            </a>
          </c:otherwise>
        </c:choose>
      </span>
      </c:if>

      <c:set var="chgAndFileName">${chg} <bs:trimWithTooltip trimCenter="true" maxlength="120" explicitTooltipText="${changedFile.fileName}">${changedFile.relativeFileName}</bs:trimWithTooltip></c:set
          ><c:choose><c:when test="${isActualModification}"><bs:popupControl
        showPopupCommand="BS.FilesPopup.showPopup(event, {parameters: '${queryParams}'});"
        hidePopupCommand="BS.FilesPopup.hidePopup();"
        stopHidingPopupCommand="BS.FilesPopup.stopHidingPopup();"
        controlId="modfiles:${modification.id}"
        clazz="fileNamePopup" type="white">${chgAndFileName}</bs:popupControl
        ><ext:includeExtensions placeId="<%=PlaceId.CHANGED_FILE_LINK%>"/></c:when
        ><c:otherwise><span style="color: var(--ring-content-background-color, #fff);">${chgAndFileName}</span></c:otherwise></c:choose>

        <div class="theme-switcher">
          <div id="themeSwitcher"></div>
        </div>

        <script>
          ReactUI.renderThemeSwitcher('themeSwitcher')
        </script>

    </div>

    <div id="desc">
      <div class="buttonbar">
        <forms:checkbox id="ignoreSpaces" name="ignoreSpaces" checked="${ignoreSpaces}" onclick="BS.DiffView.ignoreSpaces(${not ignoreSpaces});"/>
        <label for="ignoreSpaces">Ignore whitespaces</label>

        <c:if test="${isActualModification}">
        <span class="openInIDE">
          <a href="#" onclick="BS.Activator.doOpen('file?file=${encodedRelativeFilename}'); return false"
             title="Open file in IDE" <bs:iconLinkStyle icon="IDE"/>>Open in IDE</a>
        </span>
        </c:if>
      </div>

      <div class="description">
        <c:choose>
          <c:when test="${isActualModification}">
            <strong><bs:changeCommitters modification="${modification}"/></strong>: <bs:out value="${modification.description}" resolverContext="${modification}"/>
          </c:when>
          <c:otherwise>
            <c:set var="userName" value="${modification.userName}"/>
            <c:if test="${not empty userName}"><strong><c:out value="${userName}"/></strong>: </c:if><bs:out value="${modification.description}" resolverContext="${modification}"/>&nbsp;
          </c:otherwise>
        </c:choose>
      </div>
    </div>

  </div>

  <div id="toolbar" class="invisible">
    <c:set var="personal" value="${param['personal']=='true'}"/>
    <span class="column-before">
      <!-- Show legend in case of comparison failure diff -->
      <c:if test="${changedFile.beforeChangeRevisionNumber eq 'Expected'}"><span class="legend"><c:out value="${changedFile.beforeChangeRevisionNumber}"/></span></c:if>
      <span class="clipboard-btn tc-icon_before icon16 tc-icon_copy" data-for="#tbefore">Copy</span>
      <c:if test="${personal}"><span class="personalBefore">Displaying LATEST repository revision</span></c:if>
    </span>
    <span class="column-tools">
      <button class="btn btn_mini previous" onclick="BS.DiffView.cc = (BS.DiffView.cc - 1 + BS.DiffView.changes.length) % BS.DiffView.changes.length; BS.DiffView.scrollToChange(); this.blur();" title="Previous change">
        <i class="icon-angle-up"></i>
      </button>
      <button class="btn btn_mini next" onclick="BS.DiffView.cc = (BS.DiffView.cc + 1) % BS.DiffView.changes.length; BS.DiffView.scrollToChange(); this.blur();" title="Next change">
        <i class="icon-angle-down"></i>
      </button>
    </span>
    <span class="column-after">
      <!-- Show legend in case of comparison failure diff -->
      <c:if test="${changedFile.afterChangeRevisionNumber eq 'Actual'}"><span class="legend"><c:out value="${changedFile.afterChangeRevisionNumber}"/></span></c:if>
      <span class="clipboard-btn tc-icon_before icon16 tc-icon_copy" data-for="#tafter">Copy</span>
    </span>
  </div>

  <div id="status"></div>

  <c:if test="${empty styles}">
    <c:set var="highlightClass">needsHighlight</c:set>
  </c:if>

  <div id="panels" class="invisible">
    <div id="dbefore" class="custom-scroll">
      <pre>
        <div id="tbefore" class="source ${highlightClass}">${before}<span id=bottom></span></div>
      </pre>
    </div>
    <div id="dmap" class="dmap">
      <div id="mapWindow"></div>
    </div>
    <div id="dafter" class="custom-scroll">
      <pre>
        <div id="tafter" class="source ${highlightClass}">${after}</div>
      </pre>
    </div>
  </div>

  <div id="contentPlain" class="hidden">
    <textarea id="tbeforePlain">
<c:out value="${beforePlain}"/>
    </textarea>
    <textarea id="tafterPlain">
<c:out value="${afterPlain}"/>
    </textarea>
  </div>
</div>

<bs:linkScript>
  /js/bs/diffView.js
  /js/highlight.pack.js
</bs:linkScript>

<script type="text/javascript">
  //[*[0-lCount, 1-lStart, 2-rCount, 3-rStart, 4-addedEmptyLines, 5-lastLine]]
  BS.DiffView.changes = [${changes}];
  BS.DiffView.fileName = "<bs:escapeForJs text="${changedFile.relativeFileName}"/>";
  BS.DiffView.beforeLines = ${beforeLines};
  BS.DiffView.loadingMessage = '<i class="icon-refresh icon-spin ring-loader-inline"></i> Calculating... (this may take a long time to complete)';
  BS.DiffView.pageUrl = '${pageUrl}';

  <%--@elvariable id="contentInlined" type="boolean"--%>
  <c:if test="${contentInlined}">
  BS.DiffView.init();
  </c:if>
</script>

<%--@elvariable id="contentIsGraphics" type="boolean"--%>
<c:if test="${isActualModification && contentIsGraphics}">
  <script type="text/javascript">
    // Process images
    <c:url value="/rawVcsModification.html" var="url"/>
    <c:set var="fileUrl"><bs:forUrl val="${changedFile.fileName}"/></c:set>
    <c:if test="${not changedFile.type.added}">
      BS.DiffView.insertIFrameWithGraphicContent(${modification.id}, ${modification.personal}, '${url}','<bs:escapeForJs text="${fileUrl}"/>','before', 'dbefore');
    </c:if>
    <c:if test="${not changedFile.type.removed}">
      BS.DiffView.insertIFrameWithGraphicContent(${modification.id}, ${modification.personal}, '${url}', '<bs:escapeForJs text="${fileUrl}"/>', 'after', 'dafter');
    </c:if>
  </script>
</c:if>

<bs:commonTemplates/>
<bs:commonDialogs/>

  </jsp:attribute>
</bs:externalPage>
