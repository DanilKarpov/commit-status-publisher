<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="props" tagdir="/WEB-INF/tags/props" %>
<jsp:useBean id="bean" class="jetbrains.buildServer.buildFeatures.artifacts.BuildCacheConstants"/>

<tr>
  <td colspan="2">
    <div><em>Accelerates builds by caching and reusing required files.<bs:help file="Build+Cache"/></em></div>
    <div class="attentionComment">
      <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
      This feature is not recommended for builds that require a clean environment, such as release builds.
    </div>
  </td>
</tr>
<tr>
  <th><label for="${bean.cacheNameKey}">Cache name:<l:star/></label></th>
  <td>
    <props:textProperty name="${bean.cacheNameKey}" className="longField" />
    <span class="smallNote">The name of cache to upload (if "Publish" is enabled) or download (if "Use Cache" is enabled).</span>
    <span class="error" id="error_${bean.cacheNameKey}"/>
    <span class="error" id="error_options"/>
  </td>
</tr>

<tr>
  <th><label for="${bean.publishCacheKey}">Publish:</label></th>
  <td>
    <props:checkboxProperty name="${bean.publishCacheKey}" onclick="BS.BuildCache.updatePublishPropertiesVisibility();"/>
    <span class="smallNote">Enable this option to allow this build configuration to publish its files and folders as a hidden artifact.</span>
  </td>
</tr>
<tr class="publishSetting">
  <th><label for="${bean.publishCacheRulesKey}">Publishing rules:<l:star/></label></th>
  <td>
    <props:multilineProperty linkTitle="Edit Rules" name="${bean.publishCacheRulesKey}"
                             rows="5" cols="58"
                             expanded="true"
                             className="longField" style="width: 99%;"/>
    <span class="error" id="error_${bean.publishCacheRulesKey}"/>
    <span class="smallNote">Paths to directories and/or files to publish. Paths can be either relative to the checkout directory or absolute, and each path should start on a new line. Wildcards are not supported.</span>
  </td>
</tr>
<tr class="publishSetting">
  <th><label for="${bean.publishOnlyChangedKey}">Publish only if changed:</label></th>
  <td>
    <props:checkboxProperty name="${bean.publishOnlyChangedKey}"/>
    <span class="smallNote">Enable this option to re-upload this cache only if either files or rules were modified since the last publishing.</span>
  </td>
</tr>
<tr>
  <th><label for="${bean.useCacheKey}">Use Cache:</label></th>
  <td>
    <props:checkboxProperty name="${bean.useCacheKey}"/>
    <span class="smallNote">If this option is enabled, TeamCity looks for a cache with the given name and downloads it to an agent before the build starts. You can share build caches between build configurations that belong to the same project. If you need to reuse multiple caches, add the required number of build features with different "Cache Name" values.</span>
  </td>
</tr>

<script type="application/javascript">
  BS.BuildCache = {
    updatePublishPropertiesVisibility: function () {
      let publishingEnabled = $j('#${bean.publishCacheKey}').prop('checked');
      let settings = $j.find('.publishSetting');
      if (publishingEnabled) {
        BS.Util.show(settings);
      } else {
        BS.Util.hide(settings);
      }
      BS.MultilineProperties.updateVisible();
    }
  };
  BS.BuildCache.updatePublishPropertiesVisibility();
</script>